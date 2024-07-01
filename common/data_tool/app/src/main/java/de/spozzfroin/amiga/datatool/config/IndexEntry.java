package de.spozzfroin.amiga.datatool.config;

import de.spozzfroin.amiga.datatool.config.sources.Source;
import de.spozzfroin.amiga.datatool.config.sources.Source.ID;

public class IndexEntry {

	public ID id;
	public int offsetOfDataInFile;
	public byte[] metadata;
	public int offset;
	public Source source;

	private IndexEntry() {
		//
	}

	public static IndexEntry create(ID theId, byte[] theMetadata, Source theSource) {
		var ie = new IndexEntry();
		ie.id = theId;
		ie.metadata = theMetadata;
		ie.source = theSource;
		return ie;
	}
}
