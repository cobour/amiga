package de.spozzfroin.amiga.datatool.config.sources;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class TiledSource extends AbstractSource {

	private record EnemySpawnInfo(String enemyType, int xpos, int ypos, int levelYpos) {
		// empty
	}

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private boolean reversedVertically;

	private int width;
	private int height;
	private int tileWidth;
	private int tileHeight;
	private List<Integer> offsets;
	private List<EnemySpawnInfo> enemySpawnInfos;

	TiledSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.TILED_PLAYFIELD;
	}

	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("reversedVertically")) {
			this.reversedVertically = (boolean) parameter.get("reversedVertically");
		} else {
			this.reversedVertically = false;
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("reading source data of \"%s\"", this.getFilename()));
		var document = this.getDocument(config);
		var playfieldData = this.getPlayfieldLayerData(document, "tiles layer");
		this.offsets = this.readAndConvertPlayfieldData(playfieldData);
		var enemiesData = this.getEnemySpawnInfoLayerData(document, "enemies layer");
		this.enemySpawnInfos = this.readAndConvertEnemySpawnInfoData(enemiesData);
	}

	@Override
	public int length() {
		return this.getPlayfieldDataLength() + this.getEnemySpawnInfoLength();
	}

	private int getPlayfieldDataLength() {
		return this.offsets.size() * 2;
	}

	private int getEnemySpawnInfoLength() {
		return this.enemySpawnInfos.size() * 16; // df_tld_enm_sizeof
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		LOG.print(String.format("writing rawdata of \"%s\"", this.getFilename()));
		//
		this.offsets.stream().forEach(o -> BINARY_VALUE_CONVERTER.writeWord(o, data));
		//
		this.enemySpawnInfos.stream().forEach(e -> {
			BINARY_VALUE_CONVERTER.writeLong(e.enemyType, data);
			BINARY_VALUE_CONVERTER.writeWord(e.xpos, data);
			BINARY_VALUE_CONVERTER.writeWord(0, data); // no fraction
			BINARY_VALUE_CONVERTER.writeWord(e.ypos, data);
			BINARY_VALUE_CONVERTER.writeWord(0, data); // no fraction
			BINARY_VALUE_CONVERTER.writeLong(e.levelYpos, data);
		});
	}

	@Override
	public List<IndexEntry> getIndex() {
		var metadata = new ByteArrayOutputStream();
		// see datafiles.i df_tld_plf_*
		BINARY_VALUE_CONVERTER.writeWord(this.width, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.height, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.tileWidth, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.tileHeight, metadata);
		BINARY_VALUE_CONVERTER.writeLong(this.getPlayfieldDataLength(), metadata);
		BINARY_VALUE_CONVERTER.writeLong(this.getEnemySpawnInfoLength(), metadata);
		return Arrays.asList(IndexEntry.create(this.getId(), metadata.toByteArray(), this));
	}

	private Document getDocument(Config config) throws Exception {
		DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document document = builder.parse(new File(config.getSourceFolder() + this.getFilename()));
		document.getDocumentElement().normalize();
		//
		Node mapNode = document.getElementsByTagName("map").item(0);
		//
		String orientation = mapNode.getAttributes().getNamedItem("orientation").getTextContent();
		if (!"orthogonal".equalsIgnoreCase(orientation)) {
			throw new IllegalArgumentException("invalid orientation");
		}
		//
		this.width = Integer.parseInt(mapNode.getAttributes().getNamedItem("width").getTextContent().trim());
		this.height = Integer.parseInt(mapNode.getAttributes().getNamedItem("height").getTextContent().trim());
		this.tileWidth = Integer.parseInt(mapNode.getAttributes().getNamedItem("tilewidth").getTextContent().trim());
		this.tileHeight = Integer.parseInt(mapNode.getAttributes().getNamedItem("tileheight").getTextContent().trim());
		//
		return document;
	}

	private Node getPlayfieldLayerData(Document document, String layerName) throws XPathExpressionException {
		var xPathFactory = XPathFactory.newInstance();
		//
		var layerExpression = xPathFactory.newXPath().compile(String.format("//layer[@name='%s']", layerName));
		var layers = (NodeList) layerExpression.evaluate(document, XPathConstants.NODESET);
		if (layers.getLength() != 1) {
			throw new IllegalStateException("layer not found: " + layerName);
		}
		var dataNodeExpression = xPathFactory.newXPath().compile("//data");
		Node dataNode = (Node) dataNodeExpression.evaluate(layers.item(0), XPathConstants.NODE);
		//
		var encoding = dataNode.getAttributes().getNamedItem("encoding").getTextContent();
		if (!"csv".equalsIgnoreCase(encoding)) {
			throw new IllegalArgumentException("invalid encoding");
		}
		//
		return dataNode;
	}

	private NodeList getEnemySpawnInfoLayerData(Document document, String layerName) throws XPathExpressionException {
		var xPathFactory = XPathFactory.newInstance();
		//
		var layerExpression = xPathFactory.newXPath().compile(String.format("//objectgroup[@name='%s']", layerName));
		var layers = (NodeList) layerExpression.evaluate(document, XPathConstants.NODESET);
		if (layers.getLength() != 1) {
			throw new IllegalStateException("layer not found: " + layerName);
		}
		//
		var element = (Element) layers.item(0);
		return element.getElementsByTagName("object");
	}

	private List<Integer> readAndConvertPlayfieldData(Node dataNode) throws IOException {
		List<List<Integer>> allOffsets = new ArrayList<>();
		String content = dataNode.getTextContent().trim();
		BufferedReader reader = new BufferedReader(new StringReader(content));
		String line = null;
		//
		while ((line = reader.readLine()) != null) {
			List<String> lineTiles = Arrays.asList(line.trim().split(","));
			List<Integer> lineOffsets = new ArrayList<>();
			lineTiles.stream().forEach(tileString -> {
				int tile = Integer.parseInt(tileString) - 1; // values in file start at 1, we need to start at zero
				int offset = tile * (this.tileWidth / 8); // calc x-offset for tile in bytes
				lineOffsets.add(Integer.valueOf(offset));
			});
			allOffsets.add(lineOffsets);
		}
		//
		if (this.reversedVertically) {
			allOffsets = allOffsets.reversed();
		}
		//
		return allOffsets.stream().flatMap(Collection::stream).collect(Collectors.toList());
	}

	private List<EnemySpawnInfo> readAndConvertEnemySpawnInfoData(NodeList nodeList) throws IOException {
		List<EnemySpawnInfo> spawnInfo = new ArrayList<>();
		//
		IntStream.range(0, nodeList.getLength()).forEach(i -> {
			var item = (Element) nodeList.item(i);
			var attributes = item.getAttributes();
			var enemyHeight = Integer.parseInt(attributes.getNamedItem("height").getNodeValue());
			var enemyType = attributes.getNamedItem("type").getNodeValue();
			var xpos = (int) Float.parseFloat(attributes.getNamedItem("x").getNodeValue());
			var levelYpos = (int) Float.parseFloat(attributes.getNamedItem("y").getNodeValue());
			var properties = this.getProperties(item);
			var spawn_add_ypos = Integer.parseInt(properties.get("spawn_add_ypos"));
			levelYpos += spawn_add_ypos;
			var ypos = (int) Float.parseFloat(attributes.getNamedItem("y").getNodeValue());
			if (spawn_add_ypos > 0) {
				ypos = spawn_add_ypos - enemyHeight;
			} else {
				ypos = -enemyHeight; // spawned on top just outside visible area when line of level is reached
			}
			spawnInfo.add(new EnemySpawnInfo(enemyType, xpos, ypos, levelYpos));
		});
		//
		spawnInfo.sort(Comparator.comparing(EnemySpawnInfo::levelYpos));
		return spawnInfo.reversed(); // descending (not ascending) needed
	}

	private Map<String, String> getProperties(Element enemy) {
		var propertiesMap = new HashMap<String, String>();
		//
		var properties = enemy.getElementsByTagName("property");
		IntStream.range(0, properties.getLength()).forEach(i -> {
			var property = (Element) properties.item(i);
			var propertyAttributes = property.getAttributes();
			propertiesMap.put(propertyAttributes.getNamedItem("name").getNodeValue(),
					propertyAttributes.getNamedItem("value").getNodeValue());
		});
		//
		return propertiesMap;
	}
}
