package de.spozzfroin.amiga.datatool.config.sources;

import java.util.LinkedHashMap;

import de.spozzfroin.amiga.datatool.config.TargetFile;

public class SourceFactory {

	public Source create(TargetFile targetFile, LinkedHashMap<String, Object> parameter) {
		// TODO: filename OR name
		var filename = (String) parameter.get("filename");
		var extension = filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
		var source = this.createInstance(targetFile, extension);
		source.initFromConfig(parameter);
		return source;
	}

	private Source createInstance(TargetFile targetFile, String extension) {
		switch (extension) {
		case "asm":
			return new AsmSource(targetFile);
		case "iff":
			return new IffSource(targetFile);
		case "mod":
			return new ModSource(targetFile);
		case "wav":
			return new WavSource(targetFile);
		case "tmx":
			return new TiledSource(targetFile);
		default:
			throw new RuntimeException("unknown extension: " + extension);
		}
	}
}
