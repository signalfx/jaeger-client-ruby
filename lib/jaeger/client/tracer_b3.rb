# frozen_string_literal: true

module Jaeger
  module Client

    # Format for Zipkin's B3 propagation
    FORMAT_B3 = 83

    class TracerB3 < Jaeger::Client::Tracer

      def inject(span_context, format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP
          carrier['x-b3-traceid'] = span_context.trace_id.to_s(16)
          carrier['x-b3-spanid'] = span_context.span_id.to_s(16)
          carrier['x-b3-parentspanid'] = span_context.parent_id.to_s(16)
          carrier['x-b3-sampled'] = span_context.flags.to_s(16)
        when OpenTracing::FORMAT_RACK
          carrier['HTTP_X_B3_TRACEID'] = span_context.trace_id.to_s(16)
          carrier['HTTP_X_B3_SPANID'] = span_context.span_id.to_s(16)
          carrier['HTTP_X_B3_PARENTSPANID'] = span_context.parent_id.to_s(16)
          carrier['HTTP_X_B3_SAMPLED'] = span_context.flags.to_s(16)
        else
          warn "Jaeger::Client with B3 propagation in format #{format} is not supported yet"
        end
      end # inject

      def extract(format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP
          parse_context_text_map(carrier)
        when OpenTracing::FORMAT_RACK
          parse_context_rack(carrier)
        else
          warn "Jaeger::Client with B3 propagation in format #{format} is not supported yet"
          nil
        end
      end # extract

      def parse_context_text_map(carrier)
        trace_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-traceid'])
        span_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-spanid'])
        parent_id = TraceId.base16_hex_id_to_uint64(carrier['x-b3-parentspanid'])
        flags = TraceId.base16_hex_id_to_uint64(carrier['x-b3-sampled'])

        return nil if span_id.nil? || trace_id.nil?
        return nil if span_id.zero? || trace_id.zero?

        SpanContext.new(
          trace_id: trace_id,
          parent_id: parent_id,
          span_id: span_id,
          flags: flags
        )
      end # parse_context_text_map

      def parse_context_rack(carrier)
        trace_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_TRACEID'])
        span_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_SPANID'])
        parent_id = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_PARENTSPANID'])
        flags = TraceId.base16_hex_id_to_uint64(carrier['HTTP_X_B3_SAMPLED'])

        return nil if span_id.nil? || trace_id.nil?
        return nil if span_id.zero? || trace_id.zero?

        SpanContext.new(
          trace_id: trace_id,
          parent_id: parent_id,
          span_id: span_id,
          flags: flags
        )
      end # parse_context_rack
    end
  end
end
