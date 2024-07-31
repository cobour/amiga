package de.spozzfroin.amiga.datatool.config.sources;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;

class ModSource extends AbstractSource {

	byte[] rawdata;

	ModSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.MOD;
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("reading source data of \"%s\"", this.getFilename()));
		byte[] allBytes = this.getAllBytes(config);
		int startPosOfSamples = this.getStartPosOfSamples(allBytes);
		this.copyRawdata(allBytes, startPosOfSamples);
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

	@Override
	protected String getIdEquLabel() {
		return super.getIdEquLabel() + (this.getParent().getMemoryType().isChip() ? "_samples" : "_mod");
	}

	private byte[] getAllBytes(Config config) throws IOException, FileNotFoundException {
		var fullFilename = config.getSourceFolder() + this.getFilename();
		Path srcPath = Paths.get(fullFilename);
		long filesize = Files.size(srcPath);
		byte[] allBytes = new byte[(int) filesize];
		try (FileInputStream fis = new FileInputStream(fullFilename)) {
			fis.read(allBytes);
		}
		return allBytes;
	}

	private int getStartPosOfSamples(byte[] allBytes) {
		byte[] patternNoBytes = Arrays.copyOfRange(allBytes, 952, 1079);
		byte maxPatternNo = patternNoBytes[0];
		for (int i = 1; i < patternNoBytes.length; i++) {
			if (patternNoBytes[i] > maxPatternNo) {
				maxPatternNo = patternNoBytes[i];
			}
		}
		int startPosOfSamples = 1084 + (++maxPatternNo * 1024);
		return startPosOfSamples;
	}

	private void copyRawdata(byte[] allBytes, int startPosOfSamples) throws IOException {
		if (this.getParent().getMemoryType().isChip()) {
			this.rawdata = Arrays.copyOfRange(allBytes, startPosOfSamples, allBytes.length);
		} else {
			this.rawdata = Arrays.copyOfRange(allBytes, 0, startPosOfSamples);
		}
	}
}
