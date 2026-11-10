---
name: update-field-notes
description: >-
  Updates the OpenShift 5 field notes in this repository from connected
  sources, starting with Red Hat Documentation and the OpenShift mirror at
  mirror.openshift.com. Searches and fetches the product page for the version
  the note names, checks published clients, installers, and images on the
  mirror, corrects claims, versions, links, and download URLs, writes the
  procedure when a page is only a pointer, and adds a release update to the
  root README and llms.txt for each release a note now depends on. Use when
  the user asks to update, verify, fill, re-check, or correct these notes or
  docs, when a product claim, version, link, flag, procedure, release, client,
  installer, or tarball may be stale, or when adding another MCP server or
  source for these notes.
---

# Update field notes

Four sources stay separate. A product page supplies claims, versions, links, and procedures. The [OpenShift mirror](https://mirror.openshift.com/pub/) supplies published client, installer, and image names. A lab record supplies what this cluster did. The [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes) supply scripts. Do not merge them.

Read `todo.md` before adding a procedure. Do not add an install folder for an item under "Disabled on 5.0.0-rc.7".

## Which source wins

- **Product claim, version, flag, URL, or requirement.** Correct it from the fetched page for the version the note is about.
- **Download URL or published filename.** The mirror listing wins. Write a URL only when that listing contains the file. A missing channel is recorded. It is not replaced with a 4.y path.
- **Lab record.** A date, cluster name, command output, or a line that says the table stays the lab record stays. If the product page disagrees, add the product fact beside it and name the disagreement.
- **Current procedure.** A command block offered as what to run now is updated when the fetched page differs.
- **Recorded command.** A command block offered as what was run on a date stays.
- **Stub.** The note says the steps are not written yet, or the body is only a product-docs link with no commands and no numbered path. Write the procedure from the fetched page, in the voice below.
- **Page that already has steps.** Correct claims and links. Do not replace the page with the book. Scripts stay in the OpenShift 4 notes unless the user asks to copy them into this repo.
- **Disabled feature.** If `todo.md` lists it under "Disabled", do not write the install.

Do not commit kubeconfigs, pull secrets, offline tokens, cloud keys, or admin passwords.

## Look up the page

Use the source in Connected sources whose subject matches the note. For a Red Hat product page, that is Red Hat Documentation. Read the tool schema before the first call in the session. For a tarball, channel, client, installer, or RHCOS image, list the OpenShift mirror instead of guessing a filename from the product page.

Ask for the version in this order:

1. The version already on the note's product-docs line, when you are checking that line.
2. OpenShift Container Platform 5.0 for the platform itself.
3. The product's own book for ROSA, ARO, ACM, Quay, GitOps, Lightspeed, Connectivity Link, OpenShift Data Foundation, and Advanced Cluster Security.

A hit from an older version, or from a different product, is not a source for new steps. Cite it as the closest hit, say it is the wrong book, and add or update a line under "Upgrades to re-check" in `todo.md`. An OpenShift Data Foundation page is not an ARO install guide. A 4.16 virtualization install page is not the 5.0 install.

On a tool error, report the error. Do not fill the gap from memory.

## Write a stub

Match the notes already in this repo:

- One short paragraph on when to use the path.
- Numbered steps. Commands in `bash` fences. Link a sibling note instead of repeating DNS, HAProxy, PXE, or the client download.
- These are the product page's steps. Do not write them as something this lab ran.
- A procedure is a guide someone can follow to build that cluster. Put the commands and the config files in the note. Use placeholders for the pull secret, the SSH key, and any other secret. `aws/README.md` is the model. Do not stop at a field name and leave the rest of the file on the product page. The product page still wins for a claim, a version, or a flag. It does not replace a config file the installer will read.
- When you edit a note, look for deprecations on the 5.0 page for that note. If the note tells you to run a command or a tool the page marks deprecated, or a tool the page does not document, take it out of the procedure. Say it is the older note's tool.

Close with:

```markdown
Product docs: [Page title](https://docs.redhat.com/...) (Product Name Version).

Check these steps on the build you are installing.
```

Use the check line on an install path. Name the binary or flag when the note is about one command.

Check a "Missing notes" box in `todo.md` only when the note now contains the procedure. Leave a box open when it says to re-run something or to record the commands you used. If you add or rename a heading the root `README.md` links to, fix that link and the matching bullet in `llms.txt`.

`README.md` is the human index. `llms.txt` lists the same notes for an agent. A new or renamed note appears in both, in the same section. The `llms.txt` bullet names the file and one clause: procedure, stub, lab record, or pointer to the OpenShift 4 notes.

## Release updates in the README

The root `README.md` is the human index. `llms.txt` is the agent map. When the page you accepted changes which release a note depends on, add or update that note's release entry. Skip this when the README already names that release. One entry per release. Do not add an entry for a page you rejected as the wrong book.

- **OpenShift build** (`5.0.0-rc.7`, `5.0.0`, a later `5.0.z`). Under "Using the cluster", add one bullet beside the release log:

  `* [5.0.z](releases/5.0.z.md) — one line from the release notes`

  Create `releases/<version>.md` from the empty table in `releases/README.md` when the file is missing. Fill Version and a product-docs link to the release notes. Leave Date, Channel, Kubernetes, Node OS, and the other cluster rows blank. Name the new file in the first paragraph of `releases/README.md`. Add one `llms.txt` bullet for that file under "Using the cluster". Do not copy measurements from an older snapshot, and do not check a publish box in `releases/5.0.0.md` because a release-notes page was fetched.

  A directory on the mirror is not by itself a README entry. Add the entry when the note you are editing depends on that payload. Take the one-line summary from the release notes. If those notes are not published, say the payload is on the mirror and link the directory.

- **Product already in the index** (an install section, Quay, ACM, GitOps, Lightspeed, Virtualization, ACS). If that bullet's label embeds the old version, change the label in `README.md` and the matching `llms.txt` bullet. If the note now depends on a release-notes page and the README has no link to it, add the link on that same bullet. Do not add a second bullet for the same product.

## Examples

**Stub.** `openshift-virt/README.md` says the install chapter found was 4.16. Do not turn that into a 5.0 procedure. `agent-based/README.md` is now a procedure. Do not replace it with the book.

**Lab record.** `whats-new/rhcos-10.md` says the observations stay the lab record. A different version in the architecture chapter goes next to the table. The measured rows stay.

**Wrong book.** A search for the OpenShift Virtualization install chapter that returns 4.16, with only the 5.0 release notes beside it, does not become an install procedure. Record the miss in `todo.md`. Do not add a README release entry for the 4.16 page.

**OpenShift release.** A fetched 5.0.1 release-notes page changes a procedure in `aws/README.md`, and the README has no 5.0.1 bullet. Add `* [5.0.1](releases/5.0.1.md)` under "Using the cluster", and create `releases/5.0.1.md` with Version `5.0.1` and the release-notes link. Leave the cluster rows empty. Add one `llms.txt` bullet for `releases/5.0.1.md`.

**Product label.** The Quay bullet says `Quay 3.18` and the fetched deploy guide is 3.19. Rename that bullet in `README.md` and in `llms.txt` to `Quay 3.19`. No second bullet.

**Mirror.** `pre-steps/README.md` says to confirm a 5.0 client tarball. List `openshift-v5/clients/ocp/<version>/` and cite `openshift-client-linux-<version>.tar.gz` only when that file is in the listing. A channel directory is not a stand-in for a numbered release. `stable-4.15` is not the 5.0 client.

## Adding another source

Add a subsection under Connected sources. Do not create a second skill. Append the source's subject and trigger terms to the `description` in this file's frontmatter.

An MCP server also needs a ready namespace and a read of each tool schema:

```markdown
### Server name

- Namespace: `namespace-id`
- Tools: `tool_name` — what to call it for, in call order
- Use when: the note subject this server documents
- Do not use for: lab records, secrets, or a claim another source owns
- On failure: report the error and do not fill the gap from memory
```

## Connected sources

### Red Hat Documentation

- Namespace: `user-red-hat-documentation`
- Tools: `redhat_docs_search`, then `redhat_docs_fetch`
- Use when: a product claim, version, link, flag, requirement, or procedure in these notes
- Do not use for: replacing a lab record, or copying a script out of the OpenShift 4 notes
- Call order:
  1. `redhat_docs_search` with an English query that names the product and version.
  2. Use the abstract only to pick a URL.
  3. `redhat_docs_fetch` on that `docs.redhat.com` URL. Pass `query`, or keep the URL `#anchor`, so the result is the section you need.
- On failure: `1001` means no hits, `1002` means the search failed, `2001` means the link is invalid. A missing book is recorded in `todo.md`.

### OpenShift mirror

- URL: `https://mirror.openshift.com/pub/`
- Use when: a note names a client, `openshift-install`, `ccoctl`, `rosa`, a channel, an RHCOS image, or another tarball, or it tells you to confirm the mirror listing
- Do not use for: install procedures, support statements, or replacing a lab record. Do not download tarballs into this repo
- Call order:
  1. For these notes, start at `openshift-v5/`. `openshift-v4/clients/ocp/latest` and `stable-4.*` are not the 5.0 client. Prefer `openshift-v5` even if a 5.0 directory also appears under `openshift-v4`.
  2. List the directory the note means. Clients and the installer are `openshift-v5/clients/ocp/<version-or-channel>/`. Other CLIs are `openshift-v5/clients/<tool>/`. RHCOS is `openshift-v5/<arch>/dependencies/rhcos/`. Advanced Cluster Security packages are `rhacs/`.
  3. Cite a filename only when the listing contains it. Client and installer names look like `openshift-client-linux-<version>.tar.gz` and `openshift-install-linux-<version>.tar.gz`.
- On a missing channel: record it in the note or in `todo.md`. Do not assume `stable-5.0`, `latest-5.0`, or `fast-5.0` exist. A channel directory can serve an older build than a numbered `5.0.z` directory. Use the directory you mean.
