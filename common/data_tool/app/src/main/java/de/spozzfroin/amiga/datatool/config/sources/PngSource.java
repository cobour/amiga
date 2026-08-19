package de.spozzfroin.amiga.datatool.config.sources;

import java.awt.image.BufferedImage;
import java.awt.image.ColorModel;
import java.awt.image.DataBufferByte;
import java.awt.image.IndexColorModel;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;

import javax.imageio.ImageIO;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;
import de.spozzfroin.amiga.datatool.config.TargetFile;
import de.spozzfroin.amiga.datatool.util.BinaryValueConverter;

// pretty much c&p from IffSource (will not win coding prize for this)
class PngSource extends AbstractSource implements GfxSource {

	private static final BinaryValueConverter BINARY_VALUE_CONVERTER = BinaryValueConverter.getInstance();

	private boolean withMask;
	private boolean invertMask;
	private boolean flatten;
	private int flattenedTileWidth;
	private int flattenedTileHeight;
	private int flattenedReducedTileCount;
	private boolean colorsOnly;
	private int colorsLimit;

	private int width;
	private int height;
	private int bitplanes;
	private List<Short> colors;
	private byte[] rawdata;
	private byte[] mask;

	public PngSource(TargetFile theParent) {
		super(theParent);
	}

	@Override
	public SourceType getType() {
		if (this.colorsOnly) {
			return SourceType.PALETTE;
		}
		return SourceType.PNG;
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
		//
		if (parameter.containsKey("colorsLimit")) {
			this.colorsLimit = (int) parameter.get("colorsLimit");
		} else {
			this.colorsLimit = -1;
		}
	}

	@Override
	public void readAndConvertSourceData(Config config) throws Exception {
		LOG.print(String.format("reading source data of \"%s\"", this.getFilename()));
		var fullFilename = config.getSourceFolder() + this.getFilename();
		//
		BufferedImage srcImage = ImageIO.read(new File(fullFilename));
		if (srcImage == null) {
			throw new IOException("could not read or decode png file");
		}
		//
		ColorModel cm = srcImage.getColorModel();
		if (!(cm instanceof IndexColorModel)) {
			throw new IllegalArgumentException("unsupported png color model");
		}
		//
		if (this.colorsOnly) {
			this.convertColors(cm);
		} else {
			this.convertBitplanes(srcImage);
		}
	}

	private void convertColors(ColorModel cm) throws Exception {
		this.colors = new ArrayList<>();
		var icm = (IndexColorModel) cm;
		var paletteSize = icm.getMapSize();
		var reds = new byte[paletteSize];
		var greens = new byte[paletteSize];
		var blues = new byte[paletteSize];
		icm.getReds(reds);
		icm.getGreens(greens);
		icm.getBlues(blues);
		for (int i = 0; i < this.colorsLimit; i++) {
			var red = Byte.toUnsignedInt(reds[i]) >> 4;
			var green = Byte.toUnsignedInt(greens[i]) >> 4;
			var blue = Byte.toUnsignedInt(blues[i]) >> 4;
			var color = "0" + Integer.toHexString(red) + Integer.toHexString(green) + Integer.toHexString(blue);
			this.colors.add(Short.parseShort(color, 16));
		}
	}

	private void convertBitplanes(BufferedImage srcImage) throws Exception {
		this.width = srcImage.getWidth();
		this.height = srcImage.getHeight();
		this.bitplanes = (int) (Math.log(this.colorsLimit) / Math.log(2));
		//
		this.readPixelData(srcImage);
		//
		if (this.flatten) {
			this.flattenRawImageData();
			if (this.flattenedReducedTileCount > 0) {
				this.reduceTiles();
			}
		}
		//
		if (this.withMask) {
			this.mask = new byte[this.rawdata.length];
			this.createMask();
		} else {
			this.mask = new byte[0];
		}
	}

	private void readPixelData(BufferedImage srcImage) throws IOException {
		int rowBytes = ((this.width + 15) / 16) * 2; // words are padded to even bytes
		byte[] pixelData = ((DataBufferByte) srcImage.getRaster().getDataBuffer()).getData();
		var out = new ByteArrayOutputStream();
		for (int y = 0; y < this.height; y++) {
			int rowOffset = y * this.width;
			for (int plane = 0; plane < this.bitplanes; plane++) {
				byte[] planeRow = new byte[rowBytes];
				for (int x = 0; x < this.width; x++) {
					int pixelIndex = pixelData[rowOffset + x] & 0xFF;
					int bit = (pixelIndex >> plane) & 1;
					if (bit == 1) {
						int bytePos = x / 8;
						int bitPos = 7 - (x % 8);
						planeRow[bytePos] |= (1 << bitPos);
					}
				}
				out.write(planeRow);
			}
		}
		this.rawdata = out.toByteArray();
	}

	private void flattenRawImageData() {
		var newRawdataSize = this.rawdata.length;
		var newRawdata = new byte[newRawdataSize];
		//
		var tilerowsToFlatten = this.height / this.flattenedTileHeight; // number of tilerows in orig data
		var sourceRowBytes = this.width / 8; // number of bytes of a single pixel row (per bitplane)
		var sourceTilerowBytes = sourceRowBytes * this.bitplanes * this.flattenedTileHeight; // number of bytes of one
																								// tilerow in orig data
		int targetIndex = 0;
		//
		for (int targetRow = 0; targetRow < this.flattenedTileHeight; targetRow++) { // number of row in one tile
			for (int bitplaneNo = 0; bitplaneNo < this.bitplanes; bitplaneNo++) { // number of bitplane
				for (int tilerow = 0; tilerow < tilerowsToFlatten; tilerow++) { // number of tilerow in orig data
					var sourceIndex = (tilerow * sourceTilerowBytes) + (bitplaneNo * sourceRowBytes)
							+ (targetRow * (sourceRowBytes * this.bitplanes));
					System.arraycopy(this.rawdata, sourceIndex, newRawdata, targetIndex, sourceRowBytes);
					targetIndex += sourceRowBytes;
				}
			}
		}
		//
		this.rawdata = newRawdata;
		this.width = this.width * tilerowsToFlatten;
		this.height = this.flattenedTileHeight;
	}

	private void reduceTiles() {
		var oldRowSizeInBytes = this.width / 8;
		var newRowSizeInBytes = (this.flattenedReducedTileCount * this.flattenedTileWidth) / 8;
		var rowCount = this.rawdata.length / oldRowSizeInBytes;
		//
		var newRawdata = new byte[rowCount * newRowSizeInBytes];
		for (int i = 0; i < rowCount; i++) {
			System.arraycopy(this.rawdata, oldRowSizeInBytes * i, newRawdata, newRowSizeInBytes * i, newRowSizeInBytes);
		}
		//
		this.rawdata = newRawdata;
		this.width = this.flattenedReducedTileCount * this.flattenedTileWidth;
	}

	private void createMask() {
		final int bytesPerRow = this.width / 8;
		for (int row = 0; row < this.height; row++) {
			for (int col = 0; col < (this.width / 8); col++) {
				// or all bytes together
				byte mask = 0;
				for (int bitplane = 0; bitplane < this.bitplanes; bitplane++) {
					int i = (row * bytesPerRow * this.bitplanes) + (bitplane * bytesPerRow) + col;
					mask = (byte) (mask | this.rawdata[i]);
				}
				if (this.invertMask) {
					int dummy = mask;
					dummy = ~dummy;
					mask = (byte) dummy;
				}
				// write mask to all bitplanes (because of interleaved format)
				for (int bitplane = 0; bitplane < this.bitplanes; bitplane++) {
					int i = (row * bytesPerRow * this.bitplanes) + (bitplane * bytesPerRow) + col;
					this.mask[i] = mask;
				}
			}
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
		// TODO Auto-generated method stub

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
			BINARY_VALUE_CONVERTER.writeWord(this.colors.size(), metadata);
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
	public int getWidth() {
		return this.width;
	}

	@Override
	public int getHeight() {
		return this.height;
	}

	@Override
	public int getBitplanes() {
		return this.bitplanes;
	}
}
