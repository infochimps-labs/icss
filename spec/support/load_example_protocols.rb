module Icss
  module Spec
    module LoadExampleProtocols

      def load_example_protocols
        [
          Dir[ENV.root_path('examples/hackboxen/**/*.icss.yaml')],
          Dir[ENV.root_path('examples/apeyeye_endpoints/**/*.icss.yaml')],
        ].flatten[0.. -1].each do |icss_filename|
          next if icss_filename =~ %r{culture/art}
          Icss::Meta::Protocol.receive_from_file(icss_filename)
        end
      end

    end
  end
end
