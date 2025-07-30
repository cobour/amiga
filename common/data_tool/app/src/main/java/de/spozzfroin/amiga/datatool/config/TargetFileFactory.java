package de.spozzfroin.amiga.datatool.config;

import java.util.LinkedHashMap;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.sources.SourceFactory;

class TargetFileFactory {

	private final SourceFactory sourceFactory = new SourceFactory();

	@SuppressWarnings("unchecked")
	TargetFile create(LinkedHashMap<String, Object> parameter, Config config) {
		var targetFile = new TargetFile();
		//
		var filename = (String) parameter.get("filename");
		targetFile.setFilename(filename);
		//
		var description = (String) parameter.get("description");
		targetFile.setDescription(description);
		//
		var memoryType = MemoryType.valueOf((String) parameter.get("memoryType"));
		targetFile.setMemoryType(memoryType);
		//
		if (parameter.containsKey("doZip")) {
			var doZip = ((Boolean) parameter.get("doZip")).booleanValue();
			targetFile.setDoZip(doZip);
		} else {
			targetFile.setDoZip(true);
		}
		//
		if (parameter.containsKey("codeFile")) {
			var codeFile = ((Boolean) parameter.get("codeFile")).booleanValue();
			targetFile.setCodeFile(codeFile);
		} else {
			targetFile.setCodeFile(false);
		}
		//
		if (parameter.containsKey("relatedFile")) {
			var relatedFileName = (String) parameter.get("relatedFile");
			TargetFile relatedFile = config.getTargetFiles().stream()
					.filter(tf -> tf.getFilename().equals(relatedFileName)).findFirst().get();
			targetFile.setRelatedFile(relatedFile);
		} else {
			targetFile.setRelatedFile(null);
		}
		//
		if (parameter.containsKey("skipIndex")) {
			var skipIndex = ((Boolean) parameter.get("skipIndex")).booleanValue();
			targetFile.setSkipIndex(skipIndex);
		} else {
			targetFile.setSkipIndex(false);
		}
		//
		var sourceParameters = (List<LinkedHashMap<String, Object>>) parameter.get("sources");
		var sources = sourceParameters.stream().map(sfp -> this.sourceFactory.create(targetFile, sfp)).toList();
		targetFile.setSources(sources);
		//
		return targetFile;
	}
}
