package de.spozzfroin.amiga.datatool.config;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.Collectors;

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
		if (parameter.containsKey("relatedFiles")) {
			var relatedFileNames = (List<String>) parameter.get("relatedFiles");
			// List<TargetFile> relatedFiles = config.getTargetFiles().stream()
			// .filter(tf ->
			// relatedFileNames.contains(tf.getFilename())).collect(Collectors.toList());
			var relatedFiles = relatedFileNames.stream().map(
					fn -> config.getTargetFiles().stream().filter(tf -> tf.getFilename().equals(fn)).findFirst().get())
					.collect(Collectors.toList());
			targetFile.setRelatedFiles(relatedFiles);
			if (targetFile.getMemoryType().isChip()) {
				throw new RuntimeException("index in other-mem files only");
			}
			var firstChipFound = false;
			for (var tf : targetFile.getRelatedFiles()) {
				switch (tf.getMemoryType()) {
				case CHIP:
					firstChipFound = true;
					break;
				case OTHER:
					if (firstChipFound) {
						throw new RuntimeException("other-mem first, then chip-mem");
					}
					break;
				}
			}
		} else {
			targetFile.setRelatedFiles(null);
		}
		//
		var sourceParameters = (List<LinkedHashMap<String, Object>>) parameter.get("sources");
		var sources = sourceParameters.stream().map(sfp -> this.sourceFactory.create(targetFile, sfp)).toList();
		targetFile.setSources(sources);
		//
		return targetFile;
	}
}
