# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

LABEL_BUILDER = proc do |env, code|
  { code: code, method: env['REQUEST_METHOD'].downcase, path: env['REQUEST_PATH'] }
end

use Prometheus::Middleware::Collector, counter_label_builder: LABEL_BUILDER, duration_label_builder: LABEL_BUILDER, metrics_prefix: 'imjacinta_http'
use Prometheus::Middleware::Exporter, path: '/internal/metrics' # Traefik is configured to 404 requests to internal/

run Rails.application
