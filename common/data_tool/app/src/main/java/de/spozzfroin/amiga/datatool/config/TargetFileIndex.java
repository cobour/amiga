package de.spozzfroin.amiga.datatool.config;

import java.io.OutputStream;
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

	void write(OutputStream data) throws Exception {
		this.createIndexEntries();
		int indexLength = this.calcIndexSize();
		this.calcOffsets(indexLength);
		this.writeTo(data);
	}

	private void createIndexEntries() {
		var allTargetFiles = new ArrayList<TargetFile>();
		allTargetFiles.add(this.targetFile);
		allTargetFiles.addAll(this.targetFile.getRelatedFiles());
		//
		this.omEntries = allTargetFiles.stream() //
				.filter(tf -> tf.getMemoryType().isOther()) //
				.map(tf -> tf.getSources()) //
				.flatMap(Collection::stream) //
				.map(s -> s.getIndex()) //
				.flatMap(Collection::stream) //
				.collect(Collectors.toList());
		//
		this.cmEntries = allTargetFiles.stream() //
				.filter(tf -> tf.getMemoryType().isChip()) //
				.map(tf -> tf.getSources()) //
				.flatMap(Collection::stream) //
				.map(s -> s.getIndex()) //
				.flatMap(Collection::stream) //
				.collect(Collectors.toList());
	}

	int calcIndexSize() {
		// header of datafile
		int indexLength = 2; // number of files (2)
		indexLength += 8 * (1 + this.targetFile.getRelatedFiles().size()); // (4 bytes filename, 4 bytes filesize)
		indexLength += 2; // number of entries (2)
		// see datafiles.i df_idx_*
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

	private void writeTo(OutputStream data) throws Exception {
		// files and sizes
		BINARY_VALUE_CONVERTER.writeWord(1 + this.targetFile.getRelatedFiles().size(), data);
		BINARY_VALUE_CONVERTER.writeLong(this.targetFile.getFilename(), data);
		BINARY_VALUE_CONVERTER.writeLong((int) this.targetFile.calcSize(this), data);
		for (var tf : this.targetFile.getRelatedFiles()) {
			BINARY_VALUE_CONVERTER.writeLong(tf.getFilename(), data);
			int size = (int) tf.calcSize(this);
			if (tf.getMemoryType().isChip()) {
				size += 0x01000000;
			}
			BINARY_VALUE_CONVERTER.writeLong(size, data);
		}
		// number of index-entries
		BINARY_VALUE_CONVERTER.writeWord(this.omEntries.size() + this.cmEntries.size(), data);
		// see datafiles.i df_idx_*
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
