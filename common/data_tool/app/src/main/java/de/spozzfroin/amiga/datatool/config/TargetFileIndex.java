package de.spozzfroin.amiga.datatool.config;

import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class TargetFileIndex {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private final TargetFile targetFile;
	private List<IndexEntry> omEntries;
	private List<IndexEntry> cmEntries;

	TargetFileIndex(TargetFile theTargetFile) {
		this.targetFile = theTargetFile;
	}

	void write(FileOutputStream data) throws Exception {
		this.createIndexEntries();
		int indexLength = this.calcIndexSize();
		this.calcOffsets(indexLength);
		this.writeTo(data);
	}

	private void createIndexEntries() {
		this.omEntries = this.targetFile.getSources().stream() //
				.map(s -> s.getIndex()) //
				.flatMap(Collection::stream) //
				.collect(Collectors.toList());
		if (this.targetFile.getRelatedFile() != null) {
			this.cmEntries = this.targetFile.getRelatedFile().getSources().stream() //
					.map(s -> s.getIndex()) //
					.flatMap(Collection::stream) //
					.collect(Collectors.toList());
		} else {
			this.cmEntries = new ArrayList<IndexEntry>();
		}
	}

	private int calcIndexSize() {
		// see datafiles.i df_idx_*
		int indexLength = 2; // number of entries (2)
		for (var indexEntry : this.omEntries) {
			indexLength += 14; // ID (4), type (4), offset of data (4) and length of metadata (2)
			indexLength += indexEntry.metadata.length;
		}
		for (var indexEntry : this.cmEntries) {
			indexLength += 14; // ID (4), type (4), offset of data (4) and length of metadata (2)
			indexLength += indexEntry.metadata.length;
		}
		return indexLength;
	}

	private void calcOffsets(int indexLength) {
		int offset = indexLength;
		for (var indexEntry : this.omEntries) {
			indexEntry.offset = offset;
			offset += indexEntry.source.length();
		}
		offset = 0;
		for (var indexEntry : this.cmEntries) {
			indexEntry.offset = offset;
			offset += indexEntry.source.length();
		}
	}

	private void writeTo(FileOutputStream data) throws Exception {
		// see datafiles.i df_idx_*
		BINARY_VALUE_CONVERTER.writeWord(this.omEntries.size() + this.cmEntries.size(), data);
		for (var indexEntry : this.omEntries) {
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.id.asInt(), data);
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.source.getType().asInt(), data);
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.offset, data);
			BINARY_VALUE_CONVERTER.writeWord(indexEntry.metadata.length, data);
			if (indexEntry.metadata.length > 0) {
				data.write(indexEntry.metadata);
			}
		}
		for (var indexEntry : this.cmEntries) {
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.id.asInt(), data);
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.source.getType().asInt(), data);
			BINARY_VALUE_CONVERTER.writeLong(indexEntry.offset + 0x01000000, data);
			BINARY_VALUE_CONVERTER.writeWord(indexEntry.metadata.length, data);
			if (indexEntry.metadata.length > 0) {
				data.write(indexEntry.metadata);
			}
		}
	}
}
