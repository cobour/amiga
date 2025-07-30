package de.spozzfroin.amiga.datatool.config;

import java.util.LinkedHashMap;
import java.util.List;

class DiskimageFileFactory {

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
		var bootblock = (String) parameter.get("bootblock");
		diskimageFile.setBootblock(bootblock);
		//
		var datafiles = (List<String>) parameter.get("datafiles");
		diskimageFile.setDatafiles(datafiles);
		//
		return diskimageFile;
	}
}
