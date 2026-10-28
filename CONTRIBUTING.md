# Contributing to kernelshark-wasm

Contributions are welcome through pull requests to
[ni/kernelshark-wasm](https://github.com/ni/kernelshark-wasm).

See [BUG_REPORTING.md](BUG_REPORTING.md) for bugs and [SECURITY.md](SECURITY.md)
for private vulnerability reporting.

## Submitting Changes

Fork the repository, create a branch, and submit a pull request describing your
changes and the checks performed.

Sign off each commit using your own name and email address:

```bash
git commit -s
```

The resulting `Signed-off-by: Your Name <you@example.com>` line certifies the
Developer Certificate of Origin below. Preserve existing authorship and sign-offs
when forwarding contributions from others.

## Building and Developing

Follow the [README](README.md) for build instructions. KernelShark changes are
maintained as patches in [patches/kernel-shark/](patches/kernel-shark/).

## Testing

Run the [local browser test suite](tests/README.md) against the compiled WASM
application. Manually test affected functionality not covered by the suite,
and note any checks you could not run.

## Developer Certificate of Origin

Developer Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

Source: [developercertificate.org](https://developercertificate.org/).

See [LICENSE](LICENSE) for licensing details.
