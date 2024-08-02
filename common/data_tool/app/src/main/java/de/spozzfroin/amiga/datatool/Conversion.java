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
		this.readAllSourceData(config, false);
		this.calcAllAdditionalData(config, false);
		this.writeAllRawData(config, false);
		this.writeIndexFile(config, false);
		// code-files
		this.readAllSourceData(config, true);
		this.calcAllAdditionalData(config, true);
		this.writeAllRawData(config, true);
		this.writeIndexFile(config, true);
	}

	private void readAllSourceData(Config config, boolean codeFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles) {
				continue;
			}
			tf.readAllSourceData(config);
		}
	}

	private void calcAllAdditionalData(Config config, boolean codeFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles) {
				continue;
			}
			tf.calcAllAdditionalData(config);
		}
	}

	private void writeAllRawData(Config config, boolean codeFiles) throws Exception {
		for (var tf : config.getTargetFiles()) {
			if (tf.isCodeFile() != codeFiles) {
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
}
