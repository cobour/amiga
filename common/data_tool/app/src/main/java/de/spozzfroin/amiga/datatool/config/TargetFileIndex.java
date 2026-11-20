package de.spozzfroin.amiga.datatool.config;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
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

	void write(Config config, OutputStream data) throws Exception {
		this.createIndexEntries();
		int indexLength = this.calcIndexSize();
		this.calcOffsets(indexLength);
		this.writeTo(data);
		this.createMemoryUsage(config);
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

	private void createMemoryUsage(Config config) throws Exception {
		// step 1 - create pseudo asm file to grab size of structs etc.
		var asmStructSizes = new HashMap<String, Integer>();
		var asmSrcFilename = config.getTempFolder() + "dummy.asm";
		var asmObjFilename = config.getTempFolder() + "dummy.o";
		// step 1a - create asm source file
		try (var bwAsmSrc = new BufferedWriter(new FileWriter(asmSrcFilename))) {
			bwAsmSrc.append(" include \"src/ingame.i\"");
			bwAsmSrc.newLine();
			bwAsmSrc.append(" include \"../common/src/system/loader.i\"");
			bwAsmSrc.newLine();
			bwAsmSrc.append(" org ig_om_sizeof ; otherwise no echo commands are processed");
			bwAsmSrc.newLine();
			bwAsmSrc.append(" echo \"ig_om_sizeof:::\",ig_om_sizeof");
			bwAsmSrc.newLine();
			bwAsmSrc.append(" echo \"ig_cm_sizeof:::\",ig_cm_sizeof");
			bwAsmSrc.newLine();
			bwAsmSrc.append(" echo \"stack_size:::\",STACK_SIZE");
			bwAsmSrc.newLine();
		}
		// step 1b - assemble source file
		var commands = new ArrayList<String>();
		commands.addAll(List.of(config.getVasm(), asmSrcFilename, "-o", asmObjFilename, "-m68000", "-Fbin"));
		var process = new ProcessBuilder(commands).directory(new File(config.getAsmWorkingFolder())).start();
		var reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
		try {
			int returnCode = process.waitFor();
			if (returnCode != 0) {
				throw new RuntimeException("assembler errors!");
			}
			// step 1c - grab output
			String line = null;
			while ((line = reader.readLine()) != null) {
				if (line.contains(":::")) {
					var elements = line.split(":::");
					asmStructSizes.put(elements[0], Integer.parseInt(elements[1]));
				}
			}
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}
		//
		// step 2 - create the docs
		var muFilename = config.getBasefolder() + "../docs/" + this.targetFile.getMemoryUsageLabel()
				+ ".memory.usage.md";
		long sizeDatafilesChip = 0;
		long sizeDatafilesOther = this.targetFile.getIndexSize();
		try (var mu = new BufferedWriter(new FileWriter(muFilename))) {
			mu.append("# chip mem data file(s)");
			mu.newLine();
			mu.append("| ID | size in bytes | filename |");
			mu.newLine();
			mu.append("| --- | --- | --- |");
			mu.newLine();
			for (var indexEntry : this.cmEntries) {
				sizeDatafilesChip += indexEntry.source.length();
				mu.append(String.format("| %s | %d | %s |", indexEntry.id.toString(), indexEntry.source.length(),
						indexEntry.source.getFilename()));
				mu.newLine();
			}
			mu.newLine();
			mu.append("# other mem data file(s)");
			mu.newLine();
			mu.append("| ID | size in bytes | filename |");
			mu.newLine();
			mu.append("| --- | --- | --- |");
			mu.newLine();
			mu.append(String.format("| file index | %d | |", this.targetFile.getIndexSize()));
			mu.newLine();
			for (var indexEntry : this.omEntries) {
				sizeDatafilesOther += indexEntry.source.length();
				mu.append(String.format("| %s | %d | %s |", indexEntry.id.toString(), indexEntry.source.length(),
						indexEntry.source.getFilename()));
				mu.newLine();
			}
			mu.newLine();
			mu.append("# summary");
			var cpuVectors = 1024;
			var cmStruct = asmStructSizes.get(this.targetFile.getMemoryUsageCmStruct());
			var omStruct = asmStructSizes.get(this.targetFile.getMemoryUsageOmStruct());
			var stackSize = asmStructSizes.get("stack_size");
			var codeFileSize = Files
					.size(Path.of(config.getTempFolder() + this.targetFile.getMemoryUsageCodeFile() + ".dat.tmp"));
			var cmTotal = cpuVectors + cmStruct + sizeDatafilesChip;
			var omTotal = stackSize + codeFileSize + omStruct + sizeDatafilesOther;
			var cmFree = (512 * 1024) - cmTotal;
			var omFree = (512 * 1024) - omTotal;
			mu.newLine();
			mu.newLine();
			mu.append("## chip mem");
			mu.newLine();
			mu.append("| description | size in bytes |");
			mu.newLine();
			mu.append("| --- | --- |");
			mu.newLine();
			mu.append(String.format("| cpu vectors | %d |", cpuVectors));
			mu.newLine();
			mu.append(String.format("| cm struct | %d |", cmStruct));
			mu.newLine();
			mu.append(String.format("| datafiles | %d |", sizeDatafilesChip));
			mu.newLine();
			mu.append(String.format("| total | %d |", cmTotal));
			mu.newLine();
			mu.append(String.format("| free | %d |", cmFree));
			mu.newLine();
			mu.newLine();
			mu.append("## other mem");
			mu.newLine();
			mu.append("| description | size in bytes |");
			mu.newLine();
			mu.append("| --- | --- |");
			mu.newLine();
			mu.append(String.format("| stack | %d |", stackSize));
			mu.newLine();
			mu.append(String.format("| code | %d |", codeFileSize));
			mu.newLine();
			mu.append(String.format("| om struct | %d |", omStruct));
			mu.newLine();
			mu.append(String.format("| datafiles | %d |", sizeDatafilesOther));
			mu.newLine();
			mu.append(String.format("| total | %d |", omTotal));
			mu.newLine();
			mu.append(String.format("| free | %d |", omFree));
			mu.newLine();
		}
	}
}
