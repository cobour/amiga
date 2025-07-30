package de.spozzfroin.amiga.datatool;

import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.ConfigReader;
import de.spozzfroin.amiga.datatool.util.SimpleLogger;

class Conversion {

	private static final SimpleLogger LOG = SimpleLogger.getInstance();

	void run(String[] args) throws Exception {
		var config = new ConfigReader().run(args);
		LOG.divider();
		LOG.print("*******************************");
		LOG.print("***** starting conversion *****");
		LOG.print("*******************************");
		// normal data-files
		this.readAllSourceData(config, false, false);
		this.calcAllAdditionalData(config, false, false);
		this.writeAllRawData(config, false, false);
		this.writeIndexFile(config, false);
		// code-files
		this.readAllSourceData(config, true, false);
		this.calcAllAdditionalData(config, true, false);
		this.writeAllRawData(config, true, false);
		this.writeIndexFile(config, true);
		// bootblock-files
		this.readAllSourceData(config, true, true);
		this.calcAllAdditionalData(config, true, true);
		this.writeAllRawData(config, true, true);
		// no index file for bootblocks
		//
		this.writeAllDiskimageFiles(config);
	}

	private void readAllSourceData(Config config, boolean codeFiles, boolean bootblockFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles || tf.isBootblockFile() != bootblockFiles) {
				continue;
			}
			tf.readAllSourceData(config);
		}
	}

	private void calcAllAdditionalData(Config config, boolean codeFiles, boolean bootblockFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles || tf.isBootblockFile() != bootblockFiles) {
				continue;
			}
			tf.calcAllAdditionalData(config);
		}
	}

	private void writeAllRawData(Config config, boolean codeFiles, boolean bootblockFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles || tf.isBootblockFile() != bootblockFiles) {
				continue;
			}
			tf.writeAllRawdata(config);
		}
	}

	private void writeIndexFile(Config config, boolean codeFiles) throws Exception {
		LOG.divider();
		LOG.print("Writing index file");
		Path indexFile = Paths.get(codeFiles ? config.getAsmIndexFilename() : config.getIndexFilename());
		try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(indexFile, StandardCharsets.UTF_8))) {
			writer.println("; generated " + LocalDateTime.now());
			if (codeFiles) {
				writer.println("; IMPORTANT: only to be used in bootblock (to avoid chicken-and-egg-problem)");
				writer.println(" ifnd ASM_FILES_INDEX_I");
				writer.println("ASM_FILES_INDEX_I equ 1");
				writer.println(" ");
			} else {
				writer.println(" ifnd FILES_INDEX_I");
				writer.println("FILES_INDEX_I equ 1");
				writer.println(" ");
				writer.println("DatFilesCount equ " + config.getTargetFiles().size());
				writer.println(" ");
			}
			//
			for (var tf : config.getTargetFiles()) {
				if (tf.isCodeFile() != codeFiles) {
					continue;
				}
				tf.writeToIndexFile(writer, codeFiles);
				writer.println(" ");
			}
			//
			if (codeFiles) {
				writer.println(" endif ; ifnd ASM_FILES_INDEX_I");
			} else {
				writer.println(" endif ; ifnd FILES_INDEX_I");
			}
		}
	}

	private void writeAllDiskimageFiles(Config config) throws Exception {
		if (config.getDiskimageFiles() == null) {
			return;
		}
		LOG.divider();
		LOG.print("Writing diskimage files");
		for (var dif : config.getDiskimageFiles()) {
			dif.create(config);
		}
	}
}
