package de.spozzfroin.amiga.datatool.config;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.stream.Collectors;
import java.util.zip.GZIPOutputStream;

import de.spozzfroin.amiga.datatool.config.sources.Source;
import de.spozzfroin.amiga.datatool.util.SimpleLogger;

public class TargetFile {

	private static final SimpleLogger LOG = SimpleLogger.getInstance();

	private String filename;
	private String description;
	private MemoryType memoryType;
	private boolean doZip;
	private boolean codeFile;
	private boolean skipIndex;
	private TargetFile relatedFile;
	private List<Source> sources;

	private long sizeRawDataFile = -1;
	private long sizeGzippedDataFile = -1;

	public void readAllSourceData(Config config) throws Exception {
		LOG.divider();
		LOG.print(String.format("reading and converting all source data from target file \"%s\"", this.filename));
		for (var sf : this.sources) {
			sf.readAndConvertSourceData(config);
		}
	}

	public void calcAllAdditionalData(Config config) throws Exception {
		LOG.divider();
		LOG.print(String.format("calculating all additional data from target file \"%s\"", this.filename));
		for (var sf : this.sources) {
			sf.calcAdditionalData(config);
		}
	}

	public void writeAllRawdata(Config config) throws Exception {
		LOG.divider();
		LOG.print(String.format("writing all rawdata from target file \"%s\"", this.filename));
		try (FileOutputStream data = new FileOutputStream(this.getDataFile(config, true).toFile())) {
			if (!this.isCodeFile() && this.memoryType == MemoryType.OTHER && !this.skipIndex) {
				var index = new TargetFileIndex(this);
				index.write(data);
			}
			for (var sf : this.sources) {
				sf.writeRawData(config, data);
			}
			data.flush();
		}
		this.sizeRawDataFile = this.getDataFile(config, true).toFile().length();
		//
		Path completeDataFile = null;
		if (this.doZip) {
			LOG.print(String.format("zipping target file %s", this.filename));
			completeDataFile = this.gzipDataFile(config);
		} else {
			LOG.print(String.format("copying target file %s", this.filename));
			Path srcFile = this.getDataFile(config, true).toFile().toPath();
			completeDataFile = this.getDataFile(config, false);
			Files.copy(srcFile, completeDataFile, StandardCopyOption.REPLACE_EXISTING);
			this.sizeGzippedDataFile = srcFile.toFile().length();
		}
		//
		Files.copy(completeDataFile, this.getTargetDataFile(config), StandardCopyOption.REPLACE_EXISTING);
	}

	private Path gzipDataFile(Config config) throws Exception {
		Path gzippedDataFile = this.getDataFile(config, false);
		try (GZIPOutputStream gos = new GZIPOutputStream(new FileOutputStream(gzippedDataFile.toFile()));
				FileInputStream fis = new FileInputStream(this.getDataFile(config, true).toFile())) {
			byte[] buffer = new byte[1024];
			int length;
			while ((length = fis.read(buffer)) > 0) {
				gos.write(buffer, 0, length);
			}
			gos.flush();
		}
		// remove first 10 bytes (GZip-Header), not needed
		byte[] contents;
		this.sizeGzippedDataFile = Files.size(gzippedDataFile);
		this.sizeGzippedDataFile -= 10;
		contents = new byte[(int) this.sizeGzippedDataFile];
		try (FileInputStream fis = new FileInputStream(gzippedDataFile.toFile())) {
			fis.skip(10);
			fis.read(contents);
		}
		try (FileOutputStream fos = new FileOutputStream(gzippedDataFile.toFile())) {
			fos.write(contents);
			fos.flush();
		}
		return gzippedDataFile;
	}

	private Path getDataFile(Config config, boolean beforeZipping) {
		StringBuilder sb = new StringBuilder(config.getTempFolder());
		sb.append(this.filename).append(".dat");
		if (beforeZipping) {
			sb.append(".tmp");
		}
		return Paths.get(sb.toString());
	}

	public Path getTargetDataFile(Config config) {
		return Paths.get(config.getTargetFolder() + this.filename + ".dat");
	}

	public void writeToIndexFile(PrintWriter writer, boolean codeFiles) throws IOException {
		writer.println("fn_" + this.description + " equ \"" + this.getIdentifier().toUpperCase() + "\"");
		writer.println(this.getIdentifier() + "_unzipped_filesize equ " + this.sizeRawDataFile);
		if (!this.isCodeFile()) {
			var idEqus = this.sources.stream().map(source -> source.getIdEqu()).collect(Collectors.toList());
			for (String idEqu : idEqus) {
				writer.println(this.getIdentifier() + "_" + idEqu);
			}
		}
		writer.flush();
	}

	public String getIdentifier() {
		return this.filename.toLowerCase();
	}

	String getFilename() {
		return this.filename;
	}

	void setFilename(String theFilename) {
		this.filename = theFilename;
	}

	void setDescription(String thedescription) {
		this.description = thedescription;
	}

	public MemoryType getMemoryType() {
		return this.memoryType;
	}

	void setMemoryType(MemoryType theMemoryType) {
		this.memoryType = theMemoryType;
	}

	public boolean isCodeFile() {
		return this.codeFile;
	}

	void setDoZip(boolean theDoZip) {
		this.doZip = theDoZip;
	}

	void setCodeFile(boolean theCodeFile) {
		this.codeFile = theCodeFile;
	}

	TargetFile getRelatedFile() {
		return this.relatedFile;
	}

	void setRelatedFile(TargetFile theRelatedFile) {
		this.relatedFile = theRelatedFile;
	}

	List<Source> getSources() {
		return this.sources;
	}

	void setSources(List<Source> sources) {
		this.sources = sources;
	}

	boolean isSkipIndex() {
		return this.skipIndex;
	}

	void setSkipIndex(boolean skipIndex) {
		this.skipIndex = skipIndex;
	}
}
