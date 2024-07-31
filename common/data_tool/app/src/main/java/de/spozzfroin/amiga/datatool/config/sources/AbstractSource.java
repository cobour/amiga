package de.spozzfroin.amiga.datatool.config.sources;

import java.util.LinkedHashMap;

import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.SimpleLogger;

abstract class AbstractSource implements Source {

	protected static final SimpleLogger LOG = SimpleLogger.getInstance();

	private final TargetFile parent;
	private String filename;
	private ID id;

	AbstractSource(TargetFile theParent) {
		this.parent = theParent;
	}

	protected TargetFile getParent() {
		return this.parent;
	}

	protected String getFilename() {
		return this.filename;
	}

	protected void setFilename(String theFilename) {
		this.filename = theFilename;
	}

	protected ID getId() {
		return this.id;
	}

	protected void setId(String theId) {
		this.id = ID.create(theId);
	}

	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		this.setFilename((String) parameter.get("filename"));
		this.setId((String) parameter.get("id"));
	}

	protected String getIdEquLabel() {
		return this.filename.substring(0, this.filename.lastIndexOf(".")) // no file extension
				.replaceAll("\\.", "") // no dots
				.replaceAll("/", "_") // no slashes
				.replaceAll("^_+", ""); // no leading underscores
	}

	@Override
	public String getIdEqu() {
		return String.format("%s equ \"%s\"", this.getIdEquLabel(), this.id.toString());
	}

	@Override
	public String toString() {
		return String.format("%s - %s", this.id, this.filename);
	}
}
