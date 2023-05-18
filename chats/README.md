# Chats used to make a processor

In this repository are the conversations I had with ChatGPT (GPT-4) which were used to make the QTcore-A1 processor. 

The first thing to note is that the processor was not made in a single chat session. 
Instead, the processor was made across multiple conversations, with only one or two topics being addressed in each. 
This was a concious decision made for two reasons: (1) the language models have a finite input/output context window, so breaking up via topics presents the models from getting lost; and (2) it also helped keep the design process organized in much the same way you as a human might organize your own development flow.

Secondly, while the development broadly flowed linearly from topic to topic, there was one exception in conversation 8 (the datapath) which was revisited after conversation 11 (the Shift Register bug fix). This was because I was adding memory mapped components to the memory bank (done in conversation 10), and those components needed wiring added to the datapath, but I didn't want to rebuild the whole lengthy datapath conversation to do so.

Finally, the conversations do not specifically result in files. Instead, they produced Verilog modules or snippets of modules that I as an engineer copied and pasted in the logical order to build up the processor itself. This is very much a co-design process, so in addition to the feedback I gave the model, I also had to handle the extraction of the code and giving it to the tooling (Xilinx Vivado and IVerilog). Overall the model wrote 100% of all code aside from the top-level I/O, which I specified according to the needs of Tiny Tapeout.

- Hammond Pearce, May 2023

## Scanning the chats automatically for metadata

1. Scan all markdown files in this directory that start with two digits and a dash, and end with `.md`
2. Conversations have titles. Examples:
 - `# 00 SPECIFICATION`
 - `# 10 SPEC BRANCH UPDATE (return to conversation 00)` 
 so, we can match them with regex.
3. Inside each conversation, messages from the User begin with `## USER` and messages from the AI begin with `## ASSISTANT`. There is also an optional tag after the `## USER` tag, `(restarts:[0-9]+)` which indicates how many times the conversation was restarted at that point. To calculate the number of messages, add up all `## USER` and `## ASSISTANT` tags, and then add the number of restarts twice (once for the user, once for the assistant - prior assistant messages are not included but were generated).

A python script is included to calculate the metadata information and present it in a table.