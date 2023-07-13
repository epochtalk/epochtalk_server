import Test.Support.Factory
build(:banned_address, ip: "127.0.0.1", weight: 1.0)
build(:banned_address, hostname: "localhost", weight: 1.0)
