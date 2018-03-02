//
//  main.swift
//  wol
//
//  Created by Kota Nakano on 3/2/18.
//  Copyright © 2018 organi2e. All rights reserved.
//
import Darwin
extension String: Error {
	
}
func parse10<T: StringProtocol>(string: T) throws -> UInt8 {
	guard let value: UInt8 = UInt8(string, radix: 10) else { throw "parsing \(string) with 10 radix" }
	return value
}
func parse16<T: StringProtocol>(string: T) throws -> UInt8 {
	guard let value: UInt8 = UInt8(string, radix: 16) else { throw "parsing \(string) with 16 radix" }
	return value
}
let portkey: String = "--port"
let addrkey: String = "--addr"
let dumpkey: String = "--verbose"
let arguments: [String: [Any]] = [
	addrkey: [""],
	portkey: [UInt16(9)],
	dumpkey: [],
]
let (options, rests): ([String: (Bool, [Any])], [String]) = getopt(default: arguments)
errno = 0
do {
	guard let port: UInt16 = options[portkey]?.1.first as? UInt16 else { throw "no valid port found"}
	guard !rests.isEmpty else { throw "no valid mac address found" }
	let verbose: Bool = options[dumpkey]?.0 ?? false
	
	
	if verbose { print("create socket") }
	let fd: Int32 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
	guard 0 < fd else {
		throw "creating socket"
	}
	defer {
		close(fd)
	}
	let buff: UnsafeMutablePointer<sockaddr_in> = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
	defer {
		buff.deallocate(capacity: 1)
	}
	if verbose { print("set port to \(port)") }
	buff.pointee = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
							   sin_family: sa_family_t(AF_INET),
							   sin_port: port,
							   sin_addr: in_addr(s_addr: 0xffffffff),
							   sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
	if let (flag, values): (Bool, [Any]) = options[addrkey], flag, let addr: String = values.first as? String {
		if verbose { print("set address to \(addr)") }
		buff.pointee.sin_addr = try in_addr(s_addr: addr.split(separator: ".").map(parse10).reversed().reduce(UInt32(0)) {
			$0 << 8 | UInt32($1)
		})
	} else {
		if verbose { print("enable broadcast") }
		guard 0 == setsockopt(fd, SOL_SOCKET, SO_BROADCAST, [Int32(1)], socklen_t(MemoryLayout<Int32>.size)) else {
			throw "enabling broadcast"
		}
	}
	try rests.forEach {
		if verbose { print("sending packet for \($0)") }
		let head: [UInt8] = [0xff]
		let body: [UInt8] = try $0.split(separator: "-").map(parse16)
		let data: [UInt8] = (Array(repeating: head, count: 6) + Array(repeating: body, count: 16)).reduce([], +)
		let sent: Int = buff.withMemoryRebound(to: sockaddr.self, capacity: 1) {
			sendto(fd, data, data.count, 0, UnsafePointer($0), socklen_t($0.pointee.sa_len))
		}
		guard sent == data.count else {
			throw "sending to"
		}
		if verbose { print("sending packet for \($0): done") }
	}
	exit(0)
} catch let error as String {
	if 0 != errno {
		perror("error at \(error)")
	} else {
		print("error at \(error)")
	}
	print("""
Usage:
	wol [options] <MAC addresses> …

Example:
	wol \(addrkey) 192.168.1.1 EA-10-DE-AD-BE-EF

Options:
	\(portkey) <port number>
		Default: 9
	\(addrkey) <IPv4 address>
		Default: broadcast
	\(dumpkey)
		Verbose flag

""")
	exit(1)
}
