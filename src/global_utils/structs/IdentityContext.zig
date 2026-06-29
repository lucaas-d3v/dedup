pub const IdentityContext = @This();

pub fn hash(_: IdentityContext, key: u64) u64 {
    return key;
}

pub fn eql(_: IdentityContext, a: u64, b: u64) bool {
    return a == b;
}
