package de.spozzfroin.amiga.datatool.config.sources;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.IntStream;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class BobTypeSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private String gfxId;
	private int width;
	private int height;

	private byte[] rawdata;

	BobTypeSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.BOB_TYPE;
	}

	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("gfxId")) {
			this.gfxId = (String) parameter.get("gfxId");
		} else {
			throw new IllegalArgumentException("gfxId not defined!");
		}
		//
		if (parameter.containsKey("width")) {
			this.width = (int) parameter.get("width");
		} else {
			throw new IllegalArgumentException("width not defined!");
		}
		//
		if (parameter.containsKey("height")) {
			this.height = (int) parameter.get("height");
		} else {
			throw new IllegalArgumentException("height not defined!");
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		var optSource = this.getParent().getSource(this.gfxId);
		if (optSource.isEmpty()) {
			throw new IllegalArgumentException("gfxId not found!");
		}
		var gfxSource = (GfxSource) optSource.get();
		var outputStream = new ByteArrayOutputStream();
		//
		var width_temp = (this.width / 8);
		var width_shift = 0;
		while (width_temp != 1) {
			width_temp /= 2;
			width_shift++;
		}
		//
		BINARY_VALUE_CONVERTER.writeLong(this.gfxId, outputStream); // bobtype_gfx_id
		BINARY_VALUE_CONVERTER.writeWord(this.width, outputStream); // bobtype_width
		BINARY_VALUE_CONVERTER.writeWord(this.height, outputStream); // bobtype_height
		BINARY_VALUE_CONVERTER.writeWord(width_shift, outputStream); // bobtype_width_shift
		BINARY_VALUE_CONVERTER.writeWord(this.width / 16, outputStream); // bobtype_width_words
		BINARY_VALUE_CONVERTER.writeWord(this.height * gfxSource.getBitplanes(), outputStream); // bobtype_height_blt
		BINARY_VALUE_CONVERTER.writeLong(0, outputStream); // bobtype_data_pointer
		BINARY_VALUE_CONVERTER.writeLong(0, outputStream); // bobtype_mask_pointer
		BINARY_VALUE_CONVERTER.writeWord((gfxSource.getWidth() - this.width) / 8, outputStream); // bobtype_src_mod_no_shift
		BINARY_VALUE_CONVERTER.writeWord(((gfxSource.getWidth() - this.width) / 8) - 2, outputStream); // bobtype_src_mod_shift
		BINARY_VALUE_CONVERTER.writeWord((256 - this.width) / 8, outputStream); // bobtype_trg_mod_no_shift
		BINARY_VALUE_CONVERTER.writeWord(((256 - this.width) / 8) - 2, outputStream); // bobtype_trg_mod_shift
		var gfxSrcRowOffset = gfxSource.getBitplanes() * (gfxSource.getWidth() / 8);
		IntStream.range(0, 64).forEach(i -> { // 64 = BobMaxHeight
			BINARY_VALUE_CONVERTER.writeLong(i * gfxSrcRowOffset, outputStream); // bobtype_row_offsets
		});
		//
		this.rawdata = outputStream.toByteArray(); // length = bobtype_sizeof
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
