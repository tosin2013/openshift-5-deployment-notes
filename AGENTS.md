# OpenShift 5 field notes

Field notes for installing and running OpenShift 5. [README.md](README.md) is the human index. [llms.txt](llms.txt) is the file map. [todo.md](todo.md) is the open list. The procedure for correcting a note from product docs or the mirror is [.cursor/skills/update-field-notes/SKILL.md](.cursor/skills/update-field-notes/SKILL.md). Follow that skill when a claim, version, link, flag, procedure, client, installer, or tarball may be stale. It says which source wins.

## Sources

Keep these four apart. A product page supplies claims, versions, links, and procedures. The [OpenShift mirror](https://mirror.openshift.com/pub/) supplies published client, installer, and image names. A lab record supplies what this cluster did. The [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes) are the OpenShift 4 install notes. An OpenShift 4 question goes there. Do not run those scripts for 5.0.

Read `todo.md` before adding a procedure. Leave an item under "Disabled on 5.0.0-rc.7" without an install folder.

Do not commit kubeconfigs, pull secrets, offline tokens, cloud keys, or admin passwords.

## Working with a user

Read `llms.txt`, open the matching note, and answer from that note.

- A stub, such as [openshift-virt/README.md](openshift-virt/README.md), means the commands are not written yet. Say that, and point at the product-docs line. Do not fill the gap from memory.
- A lab line in [cluster/this-lab.md](cluster/this-lab.md), [releases/](releases/README.md), or a page that says the observations stay the lab record is that cluster on that date.
- A command block offered as what to run now can be followed. A command block offered as what was run on a date stays a record.
- When the note says the scripts stay in the OpenShift 4 notes, send the user to [that repo](https://github.com/tosin2013/openshift-4-deployment-notes). Those scripts were written for 4.y and are not run for 5.0.
- When `todo.md` lists the feature under "Disabled on 5.0.0-rc.7", do not offer an install.
- Tell the user to re-check the steps on the build they are installing. Clients and the installer in these notes come from a numbered directory under `openshift-v5/`. A `stable-4.*` path is not this client.
- Link a sibling note instead of repeating DNS, HAProxy, PXE, or the client download.
- Do not ask the user to paste a kubeconfig, pull secret, token, cloud key, or password into this repo.

## Adding a note

One folder, one `README.md`:

- One short paragraph on when to use the path.
- Numbered steps. Commands in `bash` fences.
- A procedure is a guide someone can follow to build that cluster. Put the commands and the config files in the note. Use placeholders for the pull secret, the SSH key, and any other secret. [aws/README.md](aws/README.md) is the model. Do not stop at a field name and leave the rest of the file on the product page.
- Link a sibling note instead of repeating DNS, HAProxy, PXE, or the client download.
- Close with a product-docs line. On an install path, add `Check these steps on the build you are installing.`
- When you edit a note, look for deprecations on the 5.0 page for that note. If the note tells you to run a command or a tool the page marks deprecated, or a tool the page does not document, take it out of the procedure. Say it is the older note's tool. `filetranspiler` on the bare-metal page was that case.

Add the same bullet to `README.md` and `llms.txt`, in the same section. A `llms.txt` bullet is `- [Name](path): one clause`, and the clause says procedure, stub, lab record, or pointer to the OpenShift 4 notes.

Leave a `todo.md` box only while the procedure is still missing. Check that box when the note contains the procedure.

Follow the skill before filling steps from docs or the mirror. Copy a script in from the OpenShift 4 notes only when the user asks. Do not add an install folder for a feature listed under "Disabled" in `todo.md`.

A release file is a separate case. The skill owns the `README.md` release entry. When you create `releases/<version>.md`, add one `llms.txt` line for that file, and name the file in the first paragraph of `releases/README.md`.
