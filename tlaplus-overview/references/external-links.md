# External Link Inventory

Policy: embed only relevant, manually verified links. Otherwise flag do-not-embed. Prefer local repo paths for factual claims.

## Official / Foundational

- `https://lamport.azurewebsites.net/tla/book.html`: Specifying Systems. Syntax/model-checking skills should map constructs to book chapters before making durable reference claims.
- `http://tlapl.us`: community site.
- `https://foundation.tlapl.us/`: governance.
- `http://proofs.tlapl.us`: TLAPS ecosystem.

## Tools / Downloads

- `https://github.com/tlaplus/tlaplus/releases`: release artifacts for `tla2tools.jar` and Toolbox.
- `https://github.com/tlaplus/vscode-tlaplus/`: recommended modern GUI workflow.
- `https://central.sonatype.com/repository/maven-snapshots/org/lamport/tla2tools/`: Maven snapshots.
- `https://adoptium.net/`: JDK provider.
- `https://ant.apache.org/`: Ant.
- `https://maven.apache.org/`: Maven.

## Community

- `https://github.com/tlaplus/tlaplus/issues`
- `https://github.com/tlaplus/rfcs/issues`
- `https://groups.google.com/g/tlaplus`
- `https://discuss.tlapl.us/`

## Papers / Examples

Use `general/performance/*/LINK.md` and `README.md` for case-specific original papers and upstream snapshots. Credit original authors. Do not treat snapshots as current upstream source.

## Flag, Do Not Embed Unless Verified

- `https://nightly.tlapl.us/*`
- `tla.msr-inria.inria.fr/*`
- `research.microsoft.com/*`
- `tlaplus.codeplex.com`, `www.codeplex.com`
- old Bitbucket links
- raw IPs, localhost, internal Microsoft SharePoint/MSR links
- old AdoptOpenJDK links; use Adoptium instead
- `apt-key add` instructions
- low-signal YouTube/asciinema/tutorial links in old changelogs

Extraction command for refresh:

```bash
rg -I -o --pcre2 "https?://[^\s\)\]\>\"']+" /mnt/mars/gitrepos/tlaplus
```
