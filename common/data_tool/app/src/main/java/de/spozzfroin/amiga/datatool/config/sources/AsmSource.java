package de.spozzfroin.amiga.datatool.config.sources;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
	private boolean isBootblock;

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
		//
		if (parameter.containsKey("isBootblock")) {
			this.isBootblock = ((Boolean) parameter.get("isBootblock")).booleanValue();
		} else {
			this.isBootblock = false;
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
		this.copyCode(config, objectFilename);
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
		if (this.isBootblock) {
			// calc checksum (use long because int is always signed in Java
			// but the checksum needs to be unsigned 32bits)
			long checksum = 0;
			for (int i = 0; i < this.rawdata.length; i += 4) {
				checksum += BINARY_VALUE_CONVERTER.getLong(this.rawdata, i);
				if (checksum > 0xffffffffL) {
					checksum -= 0x100000000L; // do the overflow
					checksum++;
				}
			}
			checksum = ~checksum;
			BINARY_VALUE_CONVERTER.setLong(this.rawdata, 4, checksum);
		}
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
				"-m68000", "-Fbin"));
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

	private void copyCode(Config config, String objectFilename) throws IOException {
		Path srcPath = Paths.get(config.getTempFolder() + objectFilename);
		long filesize = Files.size(srcPath);
		if (this.isBootblock) {
			if (filesize > 1024) {
				throw new IllegalStateException("Bootblock too large!!");
			}
			filesize = 1024;
		}
		this.rawdata = new byte[(int) filesize];
		try (FileInputStream fis = new FileInputStream(config.getTempFolder() + objectFilename)) {
			fis.read(this.rawdata);
		}
	}
}
