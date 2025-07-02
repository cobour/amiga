package de.spozzfroin.amiga.datatool.config.sources;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.Collectors;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class AsmSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private List<String> defines;
	private byte[] rawdata;
	private int bin_length;

	AsmSource(TargetFile theParent) {
		super(theParent);
	}

	@SuppressWarnings("unchecked")
	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("defines")) {
			this.defines = ((ArrayList<String>) parameter.get("defines")).stream().map(s -> "-D" + s)
					.collect(Collectors.toList());
		} else {
			this.defines = new ArrayList<>();
		}
	}

	@Override
	public SourceType getType() {
		return SourceType.ASSEMBLER;
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("assembling \"%s\"", this.getFilename()));
		var objectFilename = this.assemble(config);
		this.copyCodeHunk(config, objectFilename);
	}

	@Override
	public int length() {
		return this.rawdata.length;
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		LOG.print(String.format("writing rawdata of \"%s\"", this.getFilename()));
		data.write(this.rawdata);
	}

	@Override
	public List<IndexEntry> getIndex() {
		return Arrays.asList(IndexEntry.create(this.getId(), new byte[0], this));
	}

	private String assemble(Config config) throws IOException {
		LOG.lightDivider();
		var sourceFilename = config.getSourceFolder() + this.getFilename();
		var objectFilename = sourceFilename.substring(sourceFilename.lastIndexOf("/") + 1).replaceFirst(".asm", ".o");
		var commands = new ArrayList<String>();
		commands.addAll(List.of(config.getVasm(), sourceFilename, "-o", config.getTempFolder() + objectFilename,
				"-m68000", "-Fhunk"));
		commands.addAll(this.defines);
		var process = new ProcessBuilder(commands).directory(new File(config.getAsmWorkingFolder())).inheritIO()
				.start();
		try {
			int returnCode = process.waitFor();
			if (returnCode != 0) {
				throw new RuntimeException("assembler errors!");
			}
			LOG.lightDivider();
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}
		return objectFilename;
	}

	private void copyCodeHunk(Config config, String objectFilename) throws IOException {
		try (FileInputStream fis = new FileInputStream(config.getTempFolder() + objectFilename)) {
			do {
				var hunkID = Integer.toHexString(AsmSource.BINARY_VALUE_CONVERTER.readLong(fis));
				var hunkLength = AsmSource.BINARY_VALUE_CONVERTER.readLong(fis) * 4; // length in longwords
				if (hunkID.equals("3e9")) { // code hunk
					this.bin_length = hunkLength;
					this.rawdata = new byte[this.bin_length];
					fis.read(this.rawdata);
				} else {
					fis.skip(hunkLength);
				}
			} while (this.rawdata == null);
		}
	}
}
