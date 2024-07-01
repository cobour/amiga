package de.spozzfroin.amiga.datatool.config.sources;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

class WavSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private int hertz;
	private short volume;
	private byte priority;
	private byte[] rawdata;

	WavSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		return SourceType.WAV;
	}

	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("volume")) {
			Integer volumeInt = (Integer) parameter.get("volume");
			this.volume = volumeInt.shortValue();
			if (this.volume < 0 || this.volume > 64) {
				throw new IllegalArgumentException();
			}
		} else {
			this.volume = 64;
		}
		//
		if (parameter.containsKey("priority")) {
			Integer priorityInt = (Integer) parameter.get("priority");
			this.priority = priorityInt.byteValue();
			if (this.priority < 1 || this.volume > 127) {
				throw new IllegalArgumentException();
			}
		} else {
			this.priority = 64;
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("reading source data of \"%s\"", this.getFilename()));
		try (FileInputStream fis = new FileInputStream(config.getSourceFolder() + this.getFilename())) {
			this.readSource(fis);
		}
	}

	@Override
	public int length() {
		return this.rawdata.length;
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		LOG.print(String.format("writing rawdata of \"%s\"", this.getFilename()));
		data.write(this.rawdata);
	}

	@Override
	public List<IndexEntry> getIndex() {
		var metadata = new ByteArrayOutputStream();
		// see ptplayer.asm sfx_*
		BINARY_VALUE_CONVERTER.writeLong(0, metadata); // must be initialized in amiga program
		BINARY_VALUE_CONVERTER.writeWord(this.rawdata.length / 2, metadata);
		BINARY_VALUE_CONVERTER.writeWord(3546895 / this.hertz, metadata); // for pal, for ntsc: 3579546 / this.hertz
		BINARY_VALUE_CONVERTER.writeWord(this.volume, metadata);
		BINARY_VALUE_CONVERTER.writeByte(-1, metadata);
		BINARY_VALUE_CONVERTER.writeByte(this.priority, metadata);
		return Arrays.asList(IndexEntry.create(this.getId(), metadata.toByteArray(), this));
	}

	private void readSource(FileInputStream src) throws IOException {
		int availableBytes = Integer.MAX_VALUE;
		do {
			String chunkID = this.readChunkID(src);
			ChunkProcessor chunkProcessor = this.getChunkProcessor(chunkID);
			chunkProcessor.process(src, this);
			availableBytes = src.available();
		} while (availableBytes > 0);
	}

	private String readChunkID(FileInputStream src) throws IOException {
		// ChunkID's are Big-Endian
		byte[] bytes = new byte[4];
		src.read(bytes);
		return new String(bytes);
	}

	private ChunkProcessor getChunkProcessor(String chunkID) {
		Optional<ChunkProcessor> opt = CHUNK_PROCESSORS.stream().filter(p -> p.id().equals(chunkID)).findFirst();
		if (opt.isPresent()) {
			return opt.get();
		}
		throw new IllegalStateException(String.format("No ChunkProcessor found for ID: %s", chunkID));
	}

	//
	// Chunk processors for WAV
	//

	private static final Set<ChunkProcessor> CHUNK_PROCESSORS = new HashSet<>();

	static {
		CHUNK_PROCESSORS.add(new RiffProcessor());
		CHUNK_PROCESSORS.add(new FmtProcessor());
		CHUNK_PROCESSORS.add(new DataProcessor());
	}

	private interface ChunkProcessor {
		String id();

		void process(FileInputStream src, WavSource uow) throws IOException;
	}

	private static class RiffProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "RIFF";
		}

		@Override
		public void process(FileInputStream src, WavSource uow) throws IOException {
			src.skip(8); // skip filelength and 'WAVE'
		}
	}

	private static class FmtProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "fmt ";
		}

		@Override
		public void process(FileInputStream src, WavSource uow) throws IOException {
			src.skip(4); // length of chunk is always 16
			int format = BINARY_VALUE_CONVERTER.readWordLE(src);
			if (format != 1) {
				throw new IllegalArgumentException("Wave-File needs to be in PCM-Format!");
			}
			src.skip(2); // channel count
			uow.hertz = BINARY_VALUE_CONVERTER.readLongLE(src);
			src.skip(6); // frame size and rate
			int bits = BINARY_VALUE_CONVERTER.readWordLE(src);
			if (bits != 8) {
				throw new IllegalArgumentException("Wave-File needs to have 8 bits!");
			}
		}
	}

	private static class DataProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "data";
		}

		@Override
		public void process(FileInputStream src, WavSource uow) throws IOException {
			int length = BINARY_VALUE_CONVERTER.readLongLE(src) + 2; // add two null-bytes at beginning of sample data
			if ((length & 1) == 1) {
				length++; // even length
			}
			uow.rawdata = new byte[length];
			uow.rawdata[0] = 0;
			uow.rawdata[1] = 0;
			uow.rawdata[length - 1] = 0; // may have been added for the length to be even, then it is not contained
											// in src data
			for (int i = 2; i < length; i++) {
				int value = BINARY_VALUE_CONVERTER.readByte(src);
				int highBit = value & 0x00000080;
				int otherBits = value & 0x0000007f;
				int target = otherBits;
				if (highBit == 0) { // invert highest bit in byte
					target += 128;
				}
				uow.rawdata[i] = (byte) target;
			}
		}
	}

}
