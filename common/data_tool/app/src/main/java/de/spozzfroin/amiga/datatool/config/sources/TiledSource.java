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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.Collectors;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class TiledSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private boolean reversedVertically;

	private int width;
	private int height;
	private int tileWidth;
	private int tileHeight;
	private List<Integer> offsets;

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
		var playfieldData = this.getLayerData(document, "tiles layer");
		this.offsets = this.readAndConvert(playfieldData);
	}

	@Override
	public int length() {
		return this.offsets.size() * 2;
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		this.offsets.stream().forEach(o -> BINARY_VALUE_CONVERTER.writeWord(o, data));
	}

	@Override
	public List<IndexEntry> getIndex() {
		var metadata = new ByteArrayOutputStream();
		// see datafiles.i df_tld_plf_*
		BINARY_VALUE_CONVERTER.writeWord(this.width, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.height, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.tileWidth, metadata);
		BINARY_VALUE_CONVERTER.writeWord(this.tileHeight, metadata);
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

	private Node getLayerData(Document document, String layerName) throws XPathExpressionException {
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

	private List<Integer> readAndConvert(Node dataNode) throws IOException {
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
}
