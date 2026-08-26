package de.spozzfroin.amiga.datatool.config.sources;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class EnemyTypeSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private String bobtypeId;
	private List<Integer> boundingBox;

	private byte[] rawdata;

	EnemyTypeSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.ENEMY_TYPE;
	}

	@SuppressWarnings("unchecked")
	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("bobtypeId")) {
			this.bobtypeId = (String) parameter.get("bobtypeId");
		} else {
			throw new IllegalArgumentException("bobtypeId not defined!");
		}
		//
		if (parameter.containsKey("boundingBox")) {
			this.boundingBox = (List<Integer>) parameter.get("boundingBox");
			if (this.boundingBox.size() != 4) {
				throw new IllegalArgumentException("boundingBox not defined correctly!");
			}
		} else {
			throw new IllegalArgumentException("boundingBox not defined!");
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		var optSource = this.getParent().getSource(this.bobtypeId);
		if (optSource.isEmpty()) {
			throw new IllegalArgumentException("bobtypeId not found!");
		}
		var outputStream = new ByteArrayOutputStream();
		//
		BINARY_VALUE_CONVERTER.writeLong(this.bobtypeId, outputStream); // enemytype_bobtype_id
		BINARY_VALUE_CONVERTER.writeLong(0, outputStream); // enemytype_bobtype_pointer
		this.boundingBox.stream().forEach(i -> {
			BINARY_VALUE_CONVERTER.writeWord(i, outputStream); // enemytype_bounding_box
		});
		//
		this.rawdata = outputStream.toByteArray(); // length = enemytype_sizeof
	}

	@Override
	public int length() {
		return this.rawdata.length;
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// not needed
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		LOG.print(String.format("writing rawdata of \"%s%s\"", this.getId().toString(), this.getFilename()));
		data.write(this.rawdata);
	}

	@Override
	public List<IndexEntry> getIndex() {
		return Arrays.asList(IndexEntry.create(this.getId(), new byte[0], this)); // no metadata
	}
}
