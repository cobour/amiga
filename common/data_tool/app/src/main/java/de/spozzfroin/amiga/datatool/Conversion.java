package de.spozzfroin.amiga.datatool;

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
		this.readAllSourceData(config, false);
		this.calcAllAdditionalData(config, false);
		this.writeAllRawData(config, false);
		// code-files
		this.readAllSourceData(config, true);
		this.calcAllAdditionalData(config, true);
		this.writeAllRawData(config, true);
		//
		this.writeAllDiskimageFiles(config);
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
