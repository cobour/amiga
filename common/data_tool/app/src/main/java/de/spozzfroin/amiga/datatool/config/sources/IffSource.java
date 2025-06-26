package de.spozzfroin.amiga.datatool.config.sources;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
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

class IffSource extends AbstractSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private boolean withMask;
	private boolean invertMask;
	private boolean flatten;
	private int flattenedTileWidth;
	private int flattenedTileHeight;
	private int flattenedReducedTileCount;
	private boolean colorsOnly;

	private int width;
	private int height;
	private int bitplanes;
	private List<Short> colors;
	private byte[] rawdata;
	private byte[] mask;

	IffSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		if (this.colorsOnly) {
			return SourceType.PALETTE;
		}
		return SourceType.IFF;
	}

	@Override
	public void initFromConfig(LinkedHashMap<String, Object> parameter) {
		super.initFromConfig(parameter);
		//
		if (parameter.containsKey("withMask")) {
			this.withMask = (boolean) parameter.get("withMask");
		} else {
			this.withMask = true;
		}
		//
		if (parameter.containsKey("invertMask")) {
			this.invertMask = (boolean) parameter.get("invertMask");
		} else {
			this.invertMask = false;
		}
		//
		if (parameter.containsKey("flattenedTileFormat")) {
			this.flatten = true;
			var tileFormat = (String) parameter.get("flattenedTileFormat");
			var values = tileFormat.split("x");
			this.flattenedTileWidth = Integer.parseInt(values[0]);
			this.flattenedTileHeight = Integer.parseInt(values[1]);
		} else {
			this.flatten = false;
			this.flattenedTileWidth = -1;
			this.flattenedTileHeight = -1;
		}
		//
		if (parameter.containsKey("flattenedReducedTileCount")) {
			this.flattenedReducedTileCount = (int) parameter.get("flattenedReducedTileCount");
		} else {
			this.flattenedReducedTileCount = -1;
		}
		//
		if (parameter.containsKey("colorsOnly")) {
			this.colorsOnly = (boolean) parameter.get("colorsOnly");
		} else {
			this.colorsOnly = false;
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("reading source data of \"%s\"", this.getFilename()));
		var fullFilename = config.getSourceFolder() + this.getFilename();
		try (FileInputStream fis = new FileInputStream(fullFilename)) {
			int availableBytes = Integer.MAX_VALUE;
			do {
				String chunkID = this.readChunkID(fis);
				ChunkProcessor chunkProcessor = this.getChunkProcessor(chunkID);
				chunkProcessor.process(fis, this);
				availableBytes = fis.available();
			} while (availableBytes > 3); // everything less than 4 bytes is invalid data (padding bytes)
		}
	}

	@Override
	public int length() {
		if (this.colorsOnly) {
			return this.colors.size() * 2;
		}
		//
		var length = this.rawdata.length;
		if (this.mask != null) {
			length += this.mask.length;
		}
		return length;
	}

	@Override
	public void calcAdditionalData(Config config) throws Exception {
		// nothing to do
	}

	@Override
	public void writeRawData(Config config, OutputStream data) throws Exception {
		if (this.colorsOnly) {
			LOG.print(String.format("writing colors of \"%s\"", this.getFilename()));
			for (short color : this.colors) {
				BINARY_VALUE_CONVERTER.writeWord(color, data);
			}
		} else {
			LOG.print(String.format("writing rawdata of \"%s\"", this.getFilename()));
			data.write(this.rawdata);
			if (this.withMask) {
				data.write(this.mask);
			}
		}
	}

	@Override
	public List<IndexEntry> getIndex() {
		var metadata = new ByteArrayOutputStream();
		if (this.colorsOnly) {
			// see datafiles.i df_cols_*
			BINARY_VALUE_CONVERTER.writeWord(this.colors.size() * 2, metadata);
		} else {
			// see datafiles.i df_iff_*
			var rawsize = (this.width / 8 * this.height * this.bitplanes); // size applies both for gfx and mask data
			BINARY_VALUE_CONVERTER.writeWord(this.width, metadata);
			BINARY_VALUE_CONVERTER.writeWord(this.height, metadata);
			BINARY_VALUE_CONVERTER.writeLong(rawsize, metadata);
			BINARY_VALUE_CONVERTER.writeByte(this.bitplanes, metadata);
			BINARY_VALUE_CONVERTER.writeByte(this.withMask ? 1 : 0, metadata);
		}
		return Arrays.asList(IndexEntry.create(this.getId(), metadata.toByteArray(), this));
	}

	@Override
	protected String getIdEquLabel() {
		return super.getIdEquLabel() + (this.colorsOnly ? "_colors" : "");
	}

	private String readChunkID(FileInputStream src) throws IOException {
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
	// processors for IFF/ILBM file chunks
	//

	private static final Set<ChunkProcessor> CHUNK_PROCESSORS = new HashSet<>();

	static {
		CHUNK_PROCESSORS.add(new FormProcessor());
		CHUNK_PROCESSORS.add(new IlbmProcessor());
		CHUNK_PROCESSORS.add(new AnnoProcessor());
		CHUNK_PROCESSORS.add(new CrngProcessor());
		CHUNK_PROCESSORS.add(new DppsProcessor());
		CHUNK_PROCESSORS.add(new DrngProcessor());
		CHUNK_PROCESSORS.add(new BmhdProcessor());
		CHUNK_PROCESSORS.add(new CamgProcessor());
		CHUNK_PROCESSORS.add(new CmapProcessor());
		CHUNK_PROCESSORS.add(new BodyProcessor());
	}

	private interface ChunkProcessor {
		String id();

		void process(FileInputStream src, IffSource uow) throws IOException;
	}

	private static class FormProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "FORM";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			src.skip(4); // file size not needed
		}
	}

	private static class IlbmProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "ILBM";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			// do nothing, just continue
		}
	}

	private static class AnnoProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "ANNO";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			src.skip(chunkSize);
		}
	}

	private static class CrngProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "CRNG";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			src.skip(chunkSize);
		}
	}

	private static class DppsProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "DPPS";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			src.skip(chunkSize);
		}
	}

	private static class DrngProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "DRNG";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			src.skip(chunkSize);
		}
	}

	private static class BmhdProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "BMHD";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			src.skip(4); // chunk size not needed
			uow.width = BINARY_VALUE_CONVERTER.readWord(src);
			uow.height = BINARY_VALUE_CONVERTER.readWord(src);
			src.skip(4); // left and top not needed
			uow.bitplanes = BINARY_VALUE_CONVERTER.readByte(src);
			int masking = BINARY_VALUE_CONVERTER.readByte(src);
			if (masking == 1) {
				throw new UnsupportedOperationException("Masking not yet supported!");
			}
			int compress = BINARY_VALUE_CONVERTER.readByte(src);
			if (compress != 1) {
				throw new UnsupportedOperationException("Uncompressed files not yet supported!");
			}
			src.skip(9); // padding byte and additional fields not needed
		}
	}

	private static class CamgProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "CAMG";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			src.skip(chunkSize);
		}
	}

	private static class CmapProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "CMAP";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			uow.colors = new ArrayList<>();
			byte[] colorBytes = new byte[chunkSize];
			src.read(colorBytes);
			//
			int i = 0;
			do {
				int red = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
				int green = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
				int blue = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
				String color = "0" + Integer.toHexString(red) + Integer.toHexString(green) + Integer.toHexString(blue);
				uow.colors.add(Short.parseShort(color, 16));
			} while (i < chunkSize);
		}
	}

	private static class BodyProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "BODY";
		}

		@Override
		public void process(FileInputStream src, IffSource uow) throws IOException {
			int chunkSize = BINARY_VALUE_CONVERTER.readLong(src);
			byte[] compressed = new byte[chunkSize];
			src.read(compressed);
			//
			int rawSize = (uow.width * uow.height * uow.bitplanes) / 8;
			uow.rawdata = new byte[rawSize];
			//
			this.readRawImageData(uow, chunkSize, compressed);
			//
			if (uow.flatten) {
				this.flattenRawImageData(uow);
				if (uow.flattenedReducedTileCount > 0) {
					this.reduceTiles(uow);
				}
			}
			//
			if (uow.withMask) {
				uow.mask = new byte[rawSize];
				this.createMask(uow);
			} else {
				uow.mask = new byte[0];
			}
		}

		private void readRawImageData(IffSource uow, int chunkSize, byte[] compressed) {
			int compressedIndex = 0;
			int rawIndex = 0;
			do {
				byte code = compressed[compressedIndex++];
				if (code == -128) {
					// no-op
				} else if (code < 0) {
					// repeat byte
					byte repeatedByte = compressed[compressedIndex++];
					int count = code;
					count *= -1;
					for (int i = 0; i < count + 1; i++) {
						uow.rawdata[rawIndex++] = repeatedByte;
					}
				} else {
					// copy bytes
					int copyBytesCount = code;
					for (int i = 0; i < copyBytesCount + 1; i++) {
						uow.rawdata[rawIndex++] = compressed[compressedIndex++];
					}
				}
			} while (compressedIndex < chunkSize);
		}

		private void flattenRawImageData(IffSource uow) {
			var newRawdataSize = uow.rawdata.length;
			var newRawdata = new byte[newRawdataSize];
			//
			var tilerowsToFlatten = uow.height / uow.flattenedTileHeight; // number of tilerows in orig data
			var sourceRowBytes = uow.width / 8; // number of bytes of a single pixel row (per bitplane)
			var sourceTilerowBytes = sourceRowBytes * uow.bitplanes * uow.flattenedTileHeight; // number of bytes of one
																								// tilerow in orig data
			int targetIndex = 0;
			//
			for (int targetRow = 0; targetRow < uow.flattenedTileHeight; targetRow++) { // number of row in one tile
				for (int bitplaneNo = 0; bitplaneNo < uow.bitplanes; bitplaneNo++) { // number of bitplane
					for (int tilerow = 0; tilerow < tilerowsToFlatten; tilerow++) { // number of tilerow in orig data
						var sourceIndex = (tilerow * sourceTilerowBytes) + (bitplaneNo * sourceRowBytes)
								+ (targetRow * (sourceRowBytes * uow.bitplanes));
						System.arraycopy(uow.rawdata, sourceIndex, newRawdata, targetIndex, sourceRowBytes);
						targetIndex += sourceRowBytes;
					}
				}
			}
			//
			uow.rawdata = newRawdata;
			uow.width = uow.width * tilerowsToFlatten;
			uow.height = uow.flattenedTileHeight;
		}

		private void reduceTiles(IffSource uow) {
			var oldRowSizeInBytes = uow.width / 8;
			var newRowSizeInBytes = (uow.flattenedReducedTileCount * uow.flattenedTileWidth) / 8;
			var rowCount = uow.rawdata.length / oldRowSizeInBytes;
			//
			var newRawdata = new byte[rowCount * newRowSizeInBytes];
			for (int i = 0; i < rowCount; i++) {
				System.arraycopy(uow.rawdata, oldRowSizeInBytes * i, newRawdata, newRowSizeInBytes * i,
						newRowSizeInBytes);
			}
			//
			uow.rawdata = newRawdata;
			uow.width = uow.flattenedReducedTileCount * uow.flattenedTileWidth;
		}

		private void createMask(IffSource uow) {
			final int bytesPerRow = uow.width / 8;
			for (int row = 0; row < uow.height; row++) {
				for (int col = 0; col < (uow.width / 8); col++) {
					// or all bytes together
					byte mask = 0;
					for (int bitplane = 0; bitplane < uow.bitplanes; bitplane++) {
						int i = (row * bytesPerRow * uow.bitplanes) + (bitplane * bytesPerRow) + col;
						mask = (byte) (mask | uow.rawdata[i]);
					}
					if (uow.invertMask) {
						int dummy = mask;
						dummy = ~dummy;
						mask = (byte) dummy;
					}
					// write mask to all bitplanes (because of interleaved format)
					for (int bitplane = 0; bitplane < uow.bitplanes; bitplane++) {
						int i = (row * bytesPerRow * uow.bitplanes) + (bitplane * bytesPerRow) + col;
						uow.mask[i] = mask;
					}
				}
			}
		}
	}
}
