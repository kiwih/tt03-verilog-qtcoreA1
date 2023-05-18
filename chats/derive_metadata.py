import os
import regex as re

MSG_METADATA_FILENAME = "msg_metadata.csv"
GLOBAL_METADATA_FILENAME = "global_metadata.csv"

#get the current working directory
cwd = os.getcwd()

#1. Scan all markdown files in this directory that start with two digits 
# and a dash, and end with `.md`
files = []
for file in os.listdir(cwd):
    if file.endswith(".md") and file[0:2].isdigit() and file[2] == "-":
        files.append(file)

#print(files)
#Extract the conversations from each file. 
# 2. Conversations have titles. Examples:
# - `# 00 SPECIFICATION`
# - `# 10 SPEC BRANCH UPDATE (return to conversation)` 
# so, we can match them with the following regex:
# - `# [0-9]{2} - [A-Z\- ]+(?:[\([a-z \)]+)?`
conversation_name_re = re.compile(r"# [0-9]{2} - [A-Z\- ]+(?:[\([a-z \)]+)?")
speaker_name_re = re.compile(r"## (USER|ASSISTANT)\ ?(?:\(#restarts:([0-9]+)\))?")
conversations = {} #stored as a dictionary of conversation_name: list of message dicts
for file in files:
    with open(file, 'r') as f:
        lines = f.readlines()
        current_conversation = None
        current_message = None
        for i in range(len(lines)):
            if conversation_name_re.match(lines[i]):
                if current_message is not None and current_conversation is not None:
                    if current_message['speaker'] is not None:
                        conversations[current_conversation].append(current_message)
                #extract conversation name from the line by removing the `# `
                current_conversation = lines[i][2:].strip()
                current_message = None
            else:
                if current_conversation is not None:
                    if current_conversation not in conversations:
                        conversations[current_conversation] = []
                    speaker_match = speaker_name_re.search(lines[i])
                    if speaker_match:
                        if current_message is not None and current_message['speaker'] is not None:
                            conversations[current_conversation].append(current_message)
                        current_message = {'speaker': None, '#restarts': 0, 'lines': []}
                        current_message['speaker'] = speaker_match.group(1)
                        if speaker_match.group(2):
                            current_message['#restarts'] = speaker_match.group(2)
                    else:
                        if current_message is not None and current_message['speaker'] is not None:
                            current_message['lines'].append(lines[i])
        if current_message is not None:
            conversations[current_conversation].append(current_message)

#sort the conversations by name
conversations = dict(sorted(conversations.items()))

total_user_msgs = 0
total_assistant_msgs = 0
total_linear_msgs = 0
total_restarts = 0
total_msgs = 0
total_user_lines = 0
total_assistant_lines = 0
total_lines = 0
total_user_chars = 0
total_assistant_chars = 0
total_chars = 0

with open(MSG_METADATA_FILENAME, 'w') as f:
    #print the conversation metadata 
    f.write("Conversation,#user_msgs,#assistant_msgs,#linear_msgs_total,#restarts,#msgs_total,#user_lines,#assistant_lines,#total_lines,#user_chars,#assistant_chars,#total_chars")
    f.write("\n")
    for conversation in conversations:
        user_msgs = 0
        assistant_msgs = 0
        restarts = 0
        user_lines = 0
        assistant_lines = 0
        user_chars = 0
        assistant_chars = 0
        #now print the speaker, the #restarts, and first non-empty line of each message
        for message in conversations[conversation]:
            if message['speaker'] == 'USER':
                user_msgs += 1
                user_lines += len(message['lines'])
                for line in message['lines']:
                    user_chars += len(line)
            elif message['speaker'] == 'ASSISTANT':
                assistant_msgs += 1
                assistant_lines += len(message['lines'])
                for line in message['lines']:
                    assistant_chars += len(line)
            restarts += int(message['#restarts'])
        f.write(f"{conversation}," +
                f"{user_msgs},{assistant_msgs},{user_msgs+assistant_msgs},{restarts},{user_msgs + assistant_msgs + restarts*2}," +
                f"{user_lines},{assistant_lines},{user_lines + assistant_lines}," +
                f"{user_chars},{assistant_chars},{user_chars + assistant_chars}")
        f.write("\n")    
        
        total_user_msgs += user_msgs
        total_assistant_msgs += assistant_msgs
        total_linear_msgs += user_msgs + assistant_msgs
        total_restarts += restarts
        total_msgs += user_msgs + assistant_msgs + restarts*2
        total_user_lines += user_lines
        total_assistant_lines += assistant_lines
        total_lines += user_lines + assistant_lines
        total_user_chars += user_chars
        total_assistant_chars += assistant_chars
        total_chars += user_chars + assistant_chars

with open(GLOBAL_METADATA_FILENAME, 'w') as f:
    f.write("Total #user_msgs,Total #assistant_msgs,Total #linear_msgs,Total #restarts,Total #msgs,Total #user_lines,Total #assistant_lines,Total #total_lines,Total #user_chars,Total #assistant_chars,Total #total_chars")
    f.write("\n")
    f.write(f"{total_user_msgs},{total_assistant_msgs},{total_linear_msgs},{total_restarts},{total_msgs},{total_user_lines},{total_assistant_lines},{total_lines},{total_user_chars},{total_assistant_chars},{total_chars}")
    f.write("\n")
    