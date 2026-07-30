package de.spozzfroin.amiga.datatool.config.sources;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.IntStream;

import org.apache.batik.anim.dom.SAXSVGDocumentFactory;
import org.apache.batik.anim.dom.SVGOMPathElement;
import org.apache.batik.anim.dom.SVGPathSupport;
import org.apache.batik.bridge.BridgeContext;
import org.apache.batik.bridge.DocumentLoader;
import org.apache.batik.bridge.GVTBuilder;
import org.apache.batik.bridge.UserAgentAdapter;
import org.apache.batik.util.XMLResourceDescriptor;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class SvgPathSource extends AbstractSource {

	private record Step(float xAdd, float yAdd, int direction) {
		// empty
	}

	private record Direction(float degreeMin, float degreeMax, int direction) {
		boolean contains(float degree) {
			return this.degreeMin <= degree && this.degreeMax >= degree;
		}
	}

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private List<Integer> numberOfSteps;
	private int numberOfDirections;
	private List<Step> steps;
	private List<Direction> degreeToDirection;

	SvgPathSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.SVG_PATH;
	}

	@SuppressWarnings("unchecked")
	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("numberOfSteps")) {
			this.numberOfSteps = (List<Integer>) parameter.get("numberOfSteps");
		} else {
			this.numberOfSteps = null;
		}
		//
		if (parameter.containsKey("numberOfDirections")) {
			this.numberOfDirections = (int) parameter.get("numberOfDirections");
		} else {
			this.numberOfDirections = -1;
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		this.steps = new ArrayList<>();
		//
		var userAgent = new UserAgentAdapter();
		var bridgeContext = new BridgeContext(userAgent, new DocumentLoader(userAgent));
		bridgeContext.setDynamicState(BridgeContext.DYNAMIC);
		//
		var svgDocument = new SAXSVGDocumentFactory(XMLResourceDescriptor.getXMLParserClassName())
				.createDocument(new File(config.getSourceFolder() + this.getFilename()).toURI().toString());
		new GVTBuilder().build(bridgeContext, svgDocument);
		IntStream.range(0, this.numberOfSteps.size()).forEach(pathNumber -> {
			var path = (SVGOMPathElement) svgDocument.getElementsByTagName("path").item(pathNumber);
			float pointLength = path.getTotalLength() / this.numberOfSteps.get(pathNumber);
			//
			this.calcDegreeToDirectionTab();
			//
			IntStream.range(0, this.numberOfSteps.get(pathNumber)).forEach(i -> {
				var source = SVGPathSupport.getPointAtLength(path, pointLength * i);
				var target = SVGPathSupport.getPointAtLength(path, pointLength * (i + 1));
				var xAdd = target.getX() - source.getX();
				var yAdd = target.getY() - source.getY();
				var degree = this.calcDegree(xAdd, yAdd);
				var direction = this.degreeToDirection.stream().filter(s -> s.contains(degree)).findAny().get();
				var step = new Step(xAdd, yAdd, direction.direction);
				this.steps.add(step);
			});
		});
	}

	@Override
	public int length() {
		return this.getTotalNumberOfSteps() * 10; // 2 longs (x- and y-add) and one word (direction) per step
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		LOG.print(String.format("writing rawdata of \"%s\"", this.getFilename()));
		this.steps.stream().forEach(s -> {
			BINARY_VALUE_CONVERTER.writeFixedPointDecimal(s.xAdd, data);
			BINARY_VALUE_CONVERTER.writeFixedPointDecimal(s.yAdd, data);
			BINARY_VALUE_CONVERTER.writeWord(s.direction, data);
		});
	}

	@Override
	public List<IndexEntry> getIndex() {
		var metadata = new ByteArrayOutputStream();
		// see datafiles.i df_svgp_*
		BINARY_VALUE_CONVERTER.writeWord(this.getTotalNumberOfSteps(), metadata);
		BINARY_VALUE_CONVERTER.writeLong(this.length(), metadata);
		return Arrays.asList(IndexEntry.create(this.getId(), metadata.toByteArray(), this));
	}

	private float calcDegree(float x, float y) {
		var radian = Math.atan2(-y, x); // atan2 expects +x right and +y up, but we need +x right and +y down
		var degree = Math.toDegrees(radian);
		if (degree < 0) {
			degree += 360;
		}
		return (float) degree;
	}

	private void calcDegreeToDirectionTab() {
		// zero degree is to the right, then counter-clockwise
		float range = 360.0f / this.numberOfDirections;
		float halfRange = range / 2.0f;
		this.degreeToDirection = new ArrayList<>();
		// first (direction right, left half)
		this.degreeToDirection.add(new Direction(0.0f, halfRange, 0));
		// middle
		IntStream.range(1, this.numberOfDirections).forEach(i -> {
			float degreeMin = (i - 1) * range + halfRange;
			var direction = new Direction(degreeMin, degreeMin + range, i);
			this.degreeToDirection.add(direction);
		});
		// last (direction right, right half)
		this.degreeToDirection.add(new Direction(360f - halfRange, 360.0f, 0));
	}

	private int getTotalNumberOfSteps() {
		return this.numberOfSteps.stream().mapToInt(Integer::intValue).sum();
	}
}
