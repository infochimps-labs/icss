module IcssTestHelper
  FALSE_PARENTS = %w[Boolean Icss::Mu::EpochTime Long Double]

  SIMPLE_TYPES_TO_TEST = {
    :null               => [ ::NilClass,              NilClass,   nil],
    :boolean            => [ ::Boolean,               TrueClass, true],
    :int                => [ ::Integer,               Integer,      1],
    :long               => [ ::Long,                  Integer,      1],
    :float              => [ ::Float,                 Float,      1.0],
    :double             => [ ::Double,                Float,      1.0],
    :string             => [ ::String,                String, "hello"],
    :bytes              => [ ::Binary,                String, "hello"],
    :binary             => [ ::Binary,                String, "hello"],
    :integer            => [ ::Integer,               Integer,      1],
    :symbol             => [::Symbol,                 Symbol,  :bob  ],
    :time               => [::Time,                   Time,    Time.now],
    :'st.file_path'     => [::Icss::St::FilePath,     String,  "/tmp"],
    :'st.regexp'        => [::Icss::St::Regexp,       String,  "hel*o"],
    :'st.url'           => [::Icss::St::Url,          String,  "bit.ly"],
    :'st.md5_hexdigest' => [::Icss::St::Md5Hexdigest, String,  "fe8a2215ae337c77a3ff99d6069e2ac9"], # "chimpy"
    :'mu.epoch_time'    => [::Icss::Mu::EpochTime,    Integer, Time.now.to_i],
  }

end
