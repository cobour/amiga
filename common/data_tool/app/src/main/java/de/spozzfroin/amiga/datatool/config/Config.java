package de.spozzfroin.amiga.datatool.config;

import java.util.List;

public class Config {

	private List<TargetFile> targetFiles;
	private String vasm;
	private String sourceFolder;
	private String tempFolder;
	private String targetFolder;
	private String asmWorkingFolder;
	private String indexFilename;
	private String asmIndexFilename;

	// not read from yaml, but calculated during initialization
	private String baseFolder;

	public List<TargetFile> getTargetFiles() {
		return this.targetFiles;
	}

	void setTargetFiles(List<TargetFile> theTargetFiles) {
		this.targetFiles = theTargetFiles;
	}

	public String getVasm() {
		return this.vasm;
	}

	void setVasm(String theVasm) {
		this.vasm = theVasm;
	}

	public String getSourceFolder() {
		return this.baseFolder + (this.sourceFolder.endsWith("/") ? this.sourceFolder : this.sourceFolder + "/");
	}

	void setSourceFolder(String theSourceFolder) {
		this.sourceFolder = theSourceFolder;
	}

	public String getTempFolder() {
		return this.baseFolder + (this.tempFolder.endsWith("/") ? this.tempFolder : this.tempFolder + "/");
	}

	void setTempFolder(String theTempFolder) {
		this.tempFolder = theTempFolder;
	}

	public String getTargetFolder() {
		return this.baseFolder + (this.targetFolder.endsWith("/") ? this.targetFolder : this.targetFolder + "/");
	}

	void setTargetFolder(String theTargetFolder) {
		this.targetFolder = theTargetFolder;
	}

	public String getAsmWorkingFolder() {
		return this.asmWorkingFolder.endsWith("/") ? this.asmWorkingFolder : this.asmWorkingFolder + "/";
	}

	void setAsmWorkingFolder(String theAsmWorkingFolder) {
		this.asmWorkingFolder = theAsmWorkingFolder;
	}

	public String getIndexFilename() {
		return this.baseFolder + this.indexFilename;
	}

	void setIndexFilename(String theIndexFilename) {
		this.indexFilename = theIndexFilename;
	}

	public String getAsmIndexFilename() {
		return this.baseFolder + this.asmIndexFilename;
	}

	void setAsmIndexFilename(String asmIndexFilename) {
		this.asmIndexFilename = asmIndexFilename;
	}

	void setBaseFolder(String theBaseFolder) {
		this.baseFolder = theBaseFolder.endsWith("/") ? theBaseFolder : theBaseFolder + "/";
	}
}
