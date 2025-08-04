package de.spozzfroin.amiga.datatool.config;

import java.util.LinkedHashMap;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.sources.SourceFactory;

class DiskimageFileFactory {

	private static final SourceFactory SOURCE_FACTORY = new SourceFactory();

	@SuppressWarnings("unchecked")
	DiskimageFile create(LinkedHashMap<String, Object> parameter, Config config) {
		var diskimageFile = new DiskimageFile();
		//
		var filename = (String) parameter.get("filename");
		diskimageFile.setFilename(filename);
		//
		var diskname = (String) parameter.get("diskname");
		diskimageFile.setDiskname(diskname);
		//
		var mainCodefile = (String) parameter.get("mainCodefile");
		diskimageFile.setMainCodefile(mainCodefile);
		//
		var datafiles = (List<String>) parameter.get("datafiles");
		diskimageFile.setDatafiles(datafiles);
		//
		var bootblockParams = (LinkedHashMap<String, Object>) ((List<?>) parameter.get("bootblock")).getFirst();
		if (bootblockParams == null) {
			throw new IllegalArgumentException("must define bootblock!");
		}
		// parent not used in AsmSource, so null is okay here
		var bootblockSource = SOURCE_FACTORY.create(null, bootblockParams);
		diskimageFile.setBootblockSource(bootblockSource);
		//
		return diskimageFile;
	}
}
