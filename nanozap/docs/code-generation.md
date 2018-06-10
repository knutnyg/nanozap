# Code generation:

### Generate swift grpc client and API code:

1. `brew install protoc`
2. `brew install wget`

3. build swift codegeneration tools
`git clone https://github.com/grpc/grpc-swift.git`
`cd grpc-swift; make`

4. fetch dependencies and use it as workdir for generation 
`git clone https://github.com/googleapis/googleapis.git`
`cd googleapis`
`wget https://github.com/lightningnetwork/lnd/blob/master/lnrpc/rpc.proto`

5. Build API
```
protoc proto.rpc \
--plugin=protoc-gen-swiftgrpc=../../grpc-swift/protoc-gen-swiftgrpc \
--plugin=protoc-gen-swift=../../grpc-swift/protoc-gen-swift \
--swift_out=. \
--swiftgrpc_out=Client=true,Server=true:.
```
6. Copy generated files into project:
- `proto.pb.swift`
- `proto.grpc.swift`



