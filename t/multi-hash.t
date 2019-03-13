#!perl6

use v6;

use Test;
use ArrayHash;

# TODO Some of these tests are redundant as the way *%_ and such is handled has
# changed since this was first written.

my ($b, %hash, @array);

sub make-iter(@o) {
    class {
        method CALL-ME() { @o.shift }
        method AT-POS($pos) { @o[$pos] }
        method perl() { @o.perl }
    }
}

my %inits =
    '01-init-hash-then-array' => {
        $b      = 2;
        %hash  := multi-hash('a' => 1, 'b' => $b, 'c' => 3, 'a' => 4);
        @array := %hash;
        make-iter(@ = 0, 1, 2, 3);
    },
    '02-init-array-then-hash' => {
        $b      = 2;
        @array := multi-hash('a' => 1, 'b' => $b, 'c' => 3, 'a' => 4);
        %hash  := @array;
        make-iter(@ = 0, 1, 2, 3);
    },
    '03-init-from-pairs' => {
        $b = 2;
        my $init = multi-hash(a => 1, b => $b, c => 3);
        $init.push: 'a' => 4;
        $init{'b'} := $b;
        @array := $init;
        %hash  := $init;
        make-iter(($init.values »-» 1).antipairs.sort».value);
    },
    '04-init-from-pairs-and-positionals' => {
        $b = 2;
        my $init = multi-hash('a' => 1, 'b' => $b, c => 3, 'a' => 4);
        @array := $init;
        %hash  := $init;
        make-iter(($init.values »-» 1).antipairs.sort».value);
    },
;

my %tests =
    '01-basic' => {
        is %hash<a>, 4, 'hash a';
        is %hash<b>, 2, 'hash b';
        is %hash<c>, 3, 'hash c';

        is @array[.[0]].key, 'a', 'array 0 key';
        is @array[.[0]].value, 1, 'array 0 value';
        is @array[.[1]].key, 'b', 'array 1 key';
        is @array[.[1]].value, 2, 'array 1 value';
        is @array[.[2]].key, 'c', 'array 2 key';
        is @array[.[2]].value, 3, 'array 2 value';
        is @array[.[3]].key, 'a', 'array 3 key';
        is @array[.[3]].value, 4, 'array 3 value';
    },
    '02-replace-hash' => {
        %hash<a> = 5;
        is %hash<a>, 5, 'hash a replaced';
        is @array[.[0]].key, 'a', 'array 0 key same';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[3]].key, 'a', 'array 3 key same';
        is @array[.[3]].value, 5, 'array 3 value replace';
    },
    '03-append-hash' => {
        %hash<d> = 5;
        is %hash<d>, 5, 'hash d added';
        is @array[4].key, 'd', 'array d key added';
        is @array[4].value, 5, 'array d value added';
    },
    '04-replace-array' => {
        @array[.[1]] = 'e' => 6;
        is %hash<b>, Any, 'hash b removed';
        is %hash<e>, 6, 'hash e added';

        @array[.[3]] = 'f' => 7;
        is %hash<a>, 1, 'hash a changed';
        is %hash<f>, 7, 'hash f added';
    },
    '05-change-init-bound-var' => {
        $b = 7;
        is %hash<b>, 7, 'hash b modified';
        is @array[.[1]].value, 7, 'array b value modified';
    },
    '06-delete-hash-squashes-blanks' => {
        %hash<b> :delete;
        is @array.elems, 3, 'after hash delete elems == 3';

        %hash<a> :delete;
        is @array.elems, 1, 'after hash delete elems == 1';
    },
    '07-delete-array-keeps-blanks' => {
        @array[1] :delete;
        is %hash.elems, 4, 'after array delete elems still == 4';
    },
    '08-perl' => {
        my @els = q[:a(1)], q[:b(2)], q[:c(3)], q[:a(4)];
        is @array.perl, q[multi-hash(] ~ @els[.[0], .[1], .[2], .[3]].join(', ') ~ q[)], "array.perl";
        is %hash.perl, q[multi-hash(] ~ @els[.[0], .[1], .[2], .[3]].join(', ') ~ q[)], "hash.perl";
    },
    '09-replace-earlier' => {
        @array[3] = 'b' => 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[.[1]].key, 'b', 'array 1 key same';
        is @array[.[1]].value, 2, 'array 1 value same';
    },
    '10-replace-later' => {
        if (.[1] == 0) {
            @array[0] = 'b' => 9;
            is %hash<b>, 9, 'hash b is changed';
            is @array[0].key, 'b', 'array 0 key same';
            is @array[0].value, 9, 'array 0 value changed';
        }
        else {
            @array[0] = 'b' => 9;
            is %hash<b>, $b, 'hash b is unchanged';
            is @array[0].key, 'b', 'array 0 key set';
            is @array[0].value, 9, 'array 0 value set';
        }
    },
    '11-bind-replace-earlier' => {
        @array[3] := 'b' => 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[.[1]].key, 'b', 'array 1 key same';
        is @array[.[1]].value, $b, 'array 1 value same';
    },
    '12-bind-replace-later' => {
        if (.[1] == 0) {
            @array[0] := 'b' => 9;
            is %hash<b>, 9, 'hash b is changed';
            is @array[0].key, 'b', 'array 0 key same';
            is @array[0].value, 9, 'array 0 value changed';
        }
        else {
            @array[0] := 'b' => 9;
            is %hash<b>, 2, 'hash b is unchanged';
            is @array[0].key, 'b', 'array 0 key set';
            is @array[0].value, 9, 'array 0 value set';
        }
    },
    '13-bind-key' => {
        %hash<a> := $b;
        $b = 10;
        is %hash<a>, 10, 'hash a changed';
        is %hash<b>, 10, 'hash b changed too';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[1]].value, $b, 'array 1 value changed';
        is @array[.[3]].value, $b, 'array 3 value changed';
    },
    '14-exists-key' => {
        ok %hash<a> :exists, 'yep a exists';
        ok %hash<b> :exists, 'yep b exists';
        ok %hash<c> :exists, 'yep c exists';
        ok %hash<d> :!exists, 'nope d does not exist';
    },
    '15-exists-pos' => {
        ok @array[0] :exists, 'yep 0 exists';
        ok @array[1] :exists, 'yep 1 exists';
        ok @array[2] :exists, 'yep 2 exists';
        ok @array[3] :exists, 'yep 3 exists';
        ok @array[4] :!exists, 'nope 4 does not exist';
    },
    '16-delete-key' => {
        my $v = %hash<b> :delete;
        is $v, $b, 'deleted value is correct';
        is %hash.elems, 3, 'deleted hash shrunk by one elem';
        is @array.elems, 3, 'delete array shrunk by one elem too';
    },
    '17-delete-pos' => {
        my $p = @array[.[1]] :delete;
        is $p.key, 'b', 'deleted key is b';
        is $p.value, $b, 'deleted value is $b';
        if .[1] == 3 {
            is %hash.elems, 3, 'deleted hash shrunk by one elem';
            is @array.elems, 3, 'deleted array shrunk by one elem too';
        }
        else {
            is %hash.elems, 4, 'deleted hash did not shrink';
            is @array.elems, 4, 'deleted array did not shrink';
        }
        is @array[.[1]], Pair, 'deleted array position is undef';
    },
    '18-push' => {
        @array.push: d => 11, 'e' => 12, b => 13, 'c' => 14;
        note '# ', @array.perl;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[.[0]].key, 'a', 'array 0 key same';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[1]].key, 'b', 'array 1 key same';
        is @array[.[1]].value, 13, 'array 1 value same';
        is @array[.[2]].key, 'c', 'array 2 key same';
        is @array[.[2]].value, 3, 'array 2 value same';
        is @array[.[3]].key, 'a', 'array 3 key same';
        is @array[.[3]].value, 4, 'array 3 value changed';

        my %remains = c => 14, d => 11, e => 12;
        for 4 .. 6 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }
    },
    '19-unshift' => {
        @array.unshift: d => 11, 'e' => 12, b => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, $b, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my %remains = d => 11, e => 12, b => 13, c => 14;
        for 0 .. 3 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }

        is @array[.[0] + 4].key, 'a', 'array 0 key same';
        is @array[.[0] + 4].value, 1, 'array 0 value same';
        is @array[.[1] + 4].key, 'b', 'array 1 key same';
        is @array[.[1] + 4].value, $b, 'array 1 value same';
        is @array[.[2] + 4].key, 'c', 'array 2 key same';
        is @array[.[2] + 4].value, 3, 'array 2 value same';
        is @array[.[3] + 4].key, 'a', 'array 3 key same';
        is @array[.[3] + 4].value, 4, 'array 3 value same';
    },
    '20-splice-push' => {
        @array.splice: 4, 0, d => 11, 'e' => 12, b => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[.[0]].key, 'a', 'array 0 key same';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[1]].key, 'b', 'array 1 key same';
        is @array[.[1]].value, $b, 'array 1 value same';
        is @array[.[2]].key, 'c', 'array 2 key same';
        is @array[.[2]].value, 3, 'array 2 value same';
        is @array[.[3]].key, 'a', 'array 3 key same';
        is @array[.[3]].value, 4, 'array 3 value same';

        my %remains = b => 13, c => 14, d => 11, e => 12;
        for 4 .. 7 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }
    },
    '21-splice-unshift' => {
        @array.splice: 0, 0, d => 11, 'e' => 12, b => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, $b, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my %remains = d => 11, e => 12, b => 13, c => 14;
        for ^4 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }

        is @array[.[0] + 4].key, 'a', 'array 0 key same';
        is @array[.[0] + 4].value, 1, 'array 0 value same';
        is @array[.[1] + 4].key, 'b', 'array 1 key same';
        is @array[.[1] + 4].value, $b, 'array 1 value same';
        is @array[.[2] + 4].key, 'c', 'array 2 key same';
        is @array[.[2] + 4].value, 3, 'array 2 value same';
        is @array[.[3] + 4].key, 'a', 'array 3 key same';
        is @array[.[3] + 4].value, 4, 'array 3 value same';
    },
    '22-splice-insert' => {
        @array.splice: 2, 0, d => 11, 'e' => 12, b => 13, 'c' => 14;

        my @orig = (.[0], .[1], .[2], .[3]).map({
            when * >= 2 { $_ + 4 }
            default     { $_ }
        });

        is %hash<a>, 4, 'hash a same';
        if (@orig[1] >= 2) {
            is %hash<b>, $b, 'hash b same';
        }
        else {
            is %hash<b>, 13, 'hash b changed';
        }
        if (@orig[2] >= 2) {
            is %hash<c>, 3, 'hash c same';
        }
        else {
            is %hash<c>, 14, 'hash c changed';
        }
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my %remains = d => 11, e => 12, b => 13, c => 14;
        for 2 .. 5 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }

        given @orig {
            is @array[.[0]].key, 'a', 'array 0 key same';
            is @array[.[0]].value, 1, 'array 0 value same';
            if (.[1] >= 2) {
                is @array[.[1]].key, 'b', 'array 1 key same';
                is @array[.[1]].value, $b, 'array 1 value same';
            }
            if (.[2] >= 2) {
                is @array[.[2]].key, 'c', 'array 2 key same';
                is @array[.[2]].value, 3, 'array 2 value same';
            }
            is @array[.[3]].key, 'a', 'array 3 key same';
            is @array[.[3]].value, 4, 'array 3 key same';
        }
    },
    '23-splice-replace' => {
        @array.splice: 1, 1, d => 11, 'e' => 12, b => 13, 'c' => 14;

        my @orig = (.[0], .[1], .[2], .[3]).map({
            when * == 1 { Nil }
            when * >= 2 { $_ + 3 }
            default     { $_ }
        });

        given @orig[0] {
            when ! .defined { is %hash<a>, 4, 'hash a changed' }
            default         { is %hash<a>, 4, 'hash a same' }
        }
        given @orig[1] {
            when ! .defined { is %hash<b>, 13, 'hash b changed' }
            when * >= 2     { is %hash<b>, $b, 'hash b same' }
            default         { is %hash<b>, 13, 'hash b changed' }
        }
        given @orig[2] {
            when ! .defined { is %hash<c>, 14, 'hash c changed' }
            when * >= 2     { is %hash<c>, 3, 'hash c same' }
            default         { is %hash<c>, 14, 'hash c changed' }
        }
        given @orig[3] {
            when ! .defined { is %hash<a>, 1, 'hash a changed' }
            default         { is %hash<a>, 4, 'hash a same' }
        }
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my %remains = d => 11, e => 12, b => 13, c => 14;
        for 1 .. 4 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }

        given @orig {
            if .[0].defined {
                is @array[.[0]].key, 'a', 'array 0 key same';
                is @array[.[0]].value, 1, 'array 0 value same';
            }
            if .[1].defined {
                is @array[.[1]].key, 'b', 'array 1 key same';
                is @array[.[1]].value, $b, 'array 1 value same';
            }
            if .[2].defined {
                is @array[.[2]].key, 'c', 'array 2 key same';
                is @array[.[2]].value, 3, 'array 2 value same';
            }
            if .[3].defined {
                is @array[.[3]].key, 'a', 'array 3 key same';
                is @array[.[3]].value, 4, 'array 3 value same';
            }
        }

    },
    '24-splice-delete' => {
        @array.splice: 1, 1;

        my @orig = (.[0], .[1], .[2], .[3]).map({
            when 0 { 0 }
            when 1 { Nil }
            when * >= 2 { $_ - 1 }
        });

        given @orig {
            if ! .[0].defined { is %hash<a>, 4, 'hash a same' }
            elsif ! .[3].defined {
                is %hash<a>, 1, 'hash a is changed';
                is @array[.[0]].key, 'a', 'array 0 key same';
                is @array[.[0]].value, 1, 'array 0 value same';
            }
            else {
                is %hash<a>, 4, 'hash a is same';
                is @array[.[0]].key, 'a', 'array 0 key same';
                is @array[.[0]].value, 1, 'array 0 value same';
            }

            if ! .[1].defined { ok %hash<b> :!exists, 'hash b deleted' }
            else {
                is %hash<b>, $b, 'hash b is same';
                is @array[.[1]].key, 'b', 'array 1 key same';
                is @array[.[1]].value, $b, 'array 1 value same';
            }

            if ! .[2].defined { ok %hash<c> :!exists, 'hash c deleted' }
            else {
                is %hash<c>, 3, 'hash c is same';
                is @array[.[2]].key, 'c', 'array 2 key same';
                is @array[.[2]].value, 3, 'array 2 value same';
            }

            if ! .[3].defined { is %hash<a>, 1, 'hash a changed' }
            else {
                is %hash<a>, 4, 'hash a is same';
                is @array[.[3]].key, 'a', 'array 3 key same';
                is @array[.[3]].value, 4, 'array 3 value same';
            }
        }
    },
;

my $rand-seed = %*ENV<TEST_RAND_SEED>;
$rand-seed //= sprintf("%04d%02d%02d", .year, .month, .day) with Date.today;
srand($rand-seed.Int);
diag("TEST_RAND_SEED = $rand-seed");

for %tests.sort.pick(*) -> (:key($desc), :value(&test)) {
    subtest {
        for %inits.sort -> (:key($init-desc), :value(&init)) {
            diag "init: $init-desc, test: $desc";
            my $o = init();
            subtest { temp $_ = $o; test() }, $init-desc;
        }
    }, $desc;
}


done-testing;
