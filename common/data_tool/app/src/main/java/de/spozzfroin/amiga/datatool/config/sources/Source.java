package de.spozzfroin.amiga.datatool.config.sources;

import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;

import de.spozzfroin.amiga.datatool.config.Config;
import de.spozzfroin.amiga.datatool.config.IndexEntry;

public interface Source {

	public class ID {
		private final String id;

		private ID(String theId) {
			this.id = theId;
		}

		public static ID create(String id) {
			if (id == null || id.length() != 4) {
				throw new IllegalArgumentException();
			}
			return new ID(id);
		}

		public int asInt() {
			var bb = ByteBuffer.wrap(this.id.getBytes(StandardCharsets.US_ASCII));
			return bb.getInt();
		}

		@Override
		public String toString() {
			return this.id;
		}
	}

	SourceType getType();

	void initFromConfig(LinkedHashMap<String, Object> parameter);

	void readAndConvertSourceData(Config config) throws Exception;

	int length(); // of rawdata that is written to target file

	void calcAdditionalData(Config config) throws Exception;

	void writeRawData(Config config, OutputStream data) throws Exception;

	List<IndexEntry> getIndex();

	String getIdEqu();
}
