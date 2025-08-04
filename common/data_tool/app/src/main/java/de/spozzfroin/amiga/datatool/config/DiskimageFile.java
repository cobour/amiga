package de.spozzfroin.amiga.datatool.config;

import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.sources.Source;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;
import de.spozzfroin.amiga.datatool.util.SimpleLogger;

public class DiskimageFile {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();
	private static final SimpleLogger LOG = SimpleLogger.getInstance();

	private static final int MAX_FILES = 50;

	private String filename;
	private String diskname;
	private Source bootblockSource;
	private String mainCodefile;
	private List<String> datafiles;
	private int fillerSize;

	public void create(Config config) throws Exception {
		//
		// add main codefile at first position of datafiles
		this.datafiles.add(0, this.mainCodefile);
		//
		// write include file for bootblock with info about main codefile
		this.writeBootblockInclude(config);
		//
		// create diskimage
		LOG.print("writing " + this.filename);
		this.fillerSize = (80 * 2 * 11 * 512);
		var path = Paths.get(config.getDiskimageFolder(), this.filename);
		try (FileOutputStream data = new FileOutputStream(path.toFile())) {
			this.addBootblock(config, data);
			this.addDirectory(config, data);
			this.addDatafiles(config, data);
			this.addFiller(config, data);
			data.flush();
		}
	}

	private void writeBootblockInclude(Config config) throws Exception {
		var includeFile = Paths.get(config.getMainCodeIncludeFilename());
		var maincodeFilename = Paths.get(config.getTargetFolder() + this.mainCodefile + ".dat");
		try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(includeFile, StandardCharsets.UTF_8))) {
			writer.println("; generated " + LocalDateTime.now());
			writer.println(" ifnd MAIN_CODE_I");
			writer.println("MAIN_CODE_I equ 1");
			writer.println(" ");
			writer.println("MAIN_CODE_FILE equ \"" + this.mainCodefile + "\"");
			writer.println("MAIN_CODE_SIZE equ " + Files.size(maincodeFilename));
			writer.println(" ");
			writer.println(" endif ; ifnd MAIN_CODE_I");
		}
	}

	private void addBootblock(Config config, OutputStream data) throws Exception {
		this.bootblockSource.readAndConvertSourceData(config);
		this.bootblockSource.calcAdditionalData(config); // currently not used in AsmSource, just for completeness
		this.bootblockSource.writeRawData(config, data);
		this.fillerSize -= 1024;
	}

	private void addDirectory(Config config, OutputStream data) throws Exception {
		int dirBlockFillerSize = 512;
		//
		// 1. write diskname as long
		if (this.diskname.length() != 4) {
			throw new IllegalArgumentException("diskname must have length of 4!");
		}
		var disknameBytes = this.diskname.getBytes(Charset.defaultCharset());
		data.write(disknameBytes);
		dirBlockFillerSize -= 4;
		//
		// 2. write number of datfiles as word
		BINARY_VALUE_CONVERTER.writeWord(this.datafiles.size(), data);
		dirBlockFillerSize -= 2;
		//
		// 3. write info about every datafile
		if (this.datafiles.size() > MAX_FILES) {
			throw new IllegalStateException("too many files on disk!");
		}
		var targetFolder = config.getTargetFolder();
		int actBlock = 3; // blocks 0+1 = bb, block 2 = directory block, datafiles starting at block 3
		for (var dffn : this.datafiles) {
			var path = Paths.get(targetFolder + dffn + ".dat");
			var size = Files.size(path);
			var sizeInLastBlock = (int) size % 512;
			var blockCount = (int) size / 512;
			if (sizeInLastBlock > 0) {
				blockCount++;
			} else {
				sizeInLastBlock = 512;
			}
			var datfilenameAsBytes = dffn.getBytes(Charset.defaultCharset());
			data.write(datfilenameAsBytes);
			BINARY_VALUE_CONVERTER.writeWord(actBlock, data);
			BINARY_VALUE_CONVERTER.writeWord(blockCount, data);
			BINARY_VALUE_CONVERTER.writeWord(sizeInLastBlock, data);
			actBlock += blockCount;
			dirBlockFillerSize -= 10;
		}
		//
		// 4. write directoryblock filler
		var filler = new byte[dirBlockFillerSize];
		data.write(filler);
		//
		// 5. set fillerSize for adf
		this.fillerSize -= 512;
	}

	private void addDatafiles(Config config, OutputStream data) throws Exception {
		var targetFolder = config.getTargetFolder();
		for (var dffn : this.datafiles) {
			var path = Paths.get(targetFolder + dffn + ".dat");
			var size = Files.size(path);
			var fillersize = (int) size % 512;
			fillersize = 512 - fillersize;
			//
			var datafileBytes = Files.readAllBytes(path);
			data.write(datafileBytes);
			//
			if (fillersize > 0) {
				var filler = new byte[fillersize];
				data.write(filler);
			}
			//
			this.fillerSize -= (size + fillersize);
		}
	}

	private void addFiller(Config config, OutputStream data) throws Exception {
		if (this.fillerSize < 0) {
			throw new IllegalStateException("diskimage is too large!");
		}
		var filler = new byte[this.fillerSize];
		data.write(filler);
	}

	void setFilename(String filename) {
		this.filename = filename;
	}

	void setDiskname(String diskname) {
		this.diskname = diskname;
	}

	void setMainCodefile(String mainCodefile) {
		this.mainCodefile = mainCodefile;
	}

	void setBootblockSource(Source bootblockSource) {
		this.bootblockSource = bootblockSource;
	}

	void setDatafiles(List<String> datafiles) {
		this.datafiles = datafiles;
	}
}
