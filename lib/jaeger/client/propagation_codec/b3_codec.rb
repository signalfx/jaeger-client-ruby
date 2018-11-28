# frozen_string_literal: true

module Jaeger
  module Client
    module PropagationCodec
      class B3Codec

        # Inject a SpanContext into the given carrier
        #
        # @param span_context [SpanContext]
        # @param carrier [carrier] A carrier object of type TEXT_MAP or RACK
        def inject(span_context, carrier)
          # to_s(16) converts to a hex string
          # rjust(16, '0') pads the string to 16 characters with '0's
          carrier['x-b3-traceid'] = span_context.trace_id.to_s(16).rjust(16, '0')
          carrier['x-b3-spanid'] = span_context.span_id.to_s(16).rjust(16, '0')
          carrier['x-b3-parentspanid'] = span_context.parent_id.to_s(16).rjust(16, '0')

          # flags (for debug) and sampled headers are mutually exclusive
          if span_context.flags == Jaeger::Client::SpanContext::Flags::DEBUG
            carrier['x-b3-flags'] = "1"
          else
            carrier['x-b3-sampled'] = span_context.flags.to_s(16)
          end
        end

        # Extract a SpanContext from a given carrier in the Text Map format
        #
        # @param carrier [Carrier] A carrier of type Text Map
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def extract_text_map(carrier)
          trace_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-traceid'])
          span_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-spanid'])
          parent_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-parentspanid'])
          flags = parse_flags(carrier['x-b3-flags'], carrier['x-b3-sampled'])

          return nil if span_id.nil? || trace_id.nil?
          return nil if span_id.zero? || trace_id.zero?

          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            flags: flags
          )
        end

        # Extract a SpanContext from a given carrier in the Rack format
        #
        # @param carrier [Carrier] A carrier of type Rack
        # @return [SpanContext] the extracted SpanContext or nil if none was extracted
        def extract_rack(carrier)
          trace_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_TRACEID'])
          span_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_SPANID'])
          parent_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_PARENTSPANID'])
          flags = parse_flags(carrier['HTTP_X_B3_FLAGS'], carrier['HTTP_X_B3_SAMPLED'])

          return nil if span_id.nil? || trace_id.nil?
          return nil if span_id.zero? || trace_id.zero?

          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            flags: flags
          )
        end

        private

        # if the flags header is '1' then the sampled header should not be present
        def parse_flags(flags_header, sampled_header)
          if flags_header == '1'
            Jaeger::Client::SpanContext::Flags::DEBUG
          else
            TraceId.base16_hex_id_to_uint64(sampled_header)
          end
        end
      end
    end
  end
end
