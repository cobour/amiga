package de.spozzfroin.amiga.datatool.config;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.yaml.snakeyaml.Yaml;

import de.spozzfroin.amiga.datatool.util.SimpleLogger;

public class ConfigReader {

	private static final SimpleLogger LOG = SimpleLogger.getInstance();
	private final TargetFileFactory targetFileFactory = new TargetFileFactory();

	public Config run(String[] args) throws Exception {
		LOG.divider();
		LOG.print("reading config");
		//
		var config = new Config();
		var vasm = this.getArgValue("vasm", args);
		config.setVasm(vasm);
		//
		var filename = this.getArgValue("config.file", args);
		var configFile = new File(filename);
		var fullFilename = configFile.getCanonicalPath().replace('\\', '/');
		var baseFolder = fullFilename.substring(0, fullFilename.lastIndexOf('/') + 1);
		config.setBaseFolder(baseFolder);
		//
		var elements = this.readConfigFile(filename);
		this.setGlobalProperties(config, elements);
		this.readTargetFiles(config, elements);
		//
		return config;
	}

	private Map<String, Object> readConfigFile(String filename) throws Exception {
		var yaml = new Yaml();
		var inputStream = new FileInputStream(filename);
		Map<String, Object> elements = yaml.load(inputStream);
		return elements;
	}

	private void setGlobalProperties(Config config, Map<String, Object> elements) {
		var sourceFolder = (String) elements.get("sourceFolder");
		config.setSourceFolder(sourceFolder);
		//
		var tempFolder = (String) elements.get("tempFolder");
		config.setTempFolder(tempFolder);
		//
		var targetFolder = (String) elements.get("targetFolder");
		config.setTargetFolder(targetFolder);
		//
		var asmWorkingFolder = (String) elements.get("asmWorkingFolder");
		config.setAsmWorkingFolder(asmWorkingFolder);
		//
		var indexFilename = (String) elements.get("indexFilename");
		config.setIndexFilename(indexFilename);
		//
		var asmIndexFilename = (String) elements.get("asmIndexFilename");
		config.setAsmIndexFilename(asmIndexFilename);
	}

	private void readTargetFiles(Config config, Map<String, Object> elements) {
		@SuppressWarnings("unchecked")
		var targetFileParameters = (List<LinkedHashMap<String, Object>>) elements.get("targetFiles");
		// no stream() here, because TargetFiles need to reference each other
		config.setTargetFiles(new ArrayList<>());
		for (var parameter : targetFileParameters) {
			var targetFile = this.targetFileFactory.create(parameter, config);
			config.getTargetFiles().add(targetFile);
		}
	}

	private String getArgValue(String argID, String... args) {
		var argsList = Arrays.asList(args);
		var arg = argsList.stream().filter(a -> a.startsWith(argID + "=")).findFirst();
		if (arg.isEmpty()) {
			return null;
		}
		var argValue = arg.get();
		argValue = argValue.substring(argValue.indexOf("=") + 1);
		return argValue;
	}
}
