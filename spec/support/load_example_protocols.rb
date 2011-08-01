module Icss
  module Spec
    module LoadExampleProtocols

      def load_example_protocols
        [
          Dir[ICSS_ROOT_DIR('examples/hackboxen/**/*.icss.yaml')],
          Dir[ICSS_ROOT_DIR('examples/apeyeye_endpoints/**/*.icss.yaml')],
        ].flatten[0.. -1].each do |icss_filename|
          next if icss_filename =~ %r{culture/art}
          Icss::Protocol.receive_from_file(icss_filename)
        end
      end

    end
  end
end
