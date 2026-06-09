# Direct Message Feature - Testing Guide

## 🧪 How to Test the Chat Feature

### Prerequisites
- 2+ Firebase test accounts (Google Sign-in)
- Both accounts should be friends with each other
- Firebase Firestore database initialized

---

## 📋 Manual Testing Checklist

### Test 1: Open Chat Tab
- [ ] Navigate to Chat tab from bottom nav
- [ ] Should see blue gradient header with "Messages" title
- [ ] Should see search bar
- [ ] If no chats yet: should see empty state with "Find Friends" button

### Test 2: Start a Conversation
- [ ] Go to Profile → Friends tab (or tap "Find Friends" from empty state)
- [ ] See list of your friends
- [ ] Tap "Chat" button next to a friend
- [ ] Should navigate to DirectMessageScreen
- [ ] Should see empty state: friend avatar + "Say hi to [name]! 👋"

### Test 3: Send Messages
- [ ] Type a message in the input field
- [ ] Purple "send" button should appear
- [ ] Tap send button
- [ ] Message should appear on the right side in purple bubble
- [ ] Message should show your time stamp below
- [ ] Single tick (✓) should show next to message

### Test 4: Receive Messages
- [ ] From another account, open the same chat
- [ ] Send a message
- [ ] First account should see message appear in real-time on left side in white bubble
- [ ] Should show friend's timestamp in grey
- [ ] Should auto-scroll to bottom

### Test 5: Message History
- [ ] Send 5+ messages back and forth
- [ ] Close and reopen the app
- [ ] All messages should still be there in order
- [ ] Scroll up to see older messages

### Test 6: Chat List
- [ ] Send messages to 2 different friends
- [ ] Go to Chat tab
- [ ] Should see both conversations listed
- [ ] Most recent conversation should be at top
- [ ] Should show last message preview
- [ ] Should show time of last message
- [ ] Should show unread badge (purple pill)

### Test 7: Search
- [ ] On Chat tab, type in search bar
- [ ] Should filter conversations by last message text
- [ ] Clear search to show all

### Test 8: Unread Badge
- [ ] Account 1 sends message but doesn't open chat
- [ ] Chat tab shows unread badge on Chat icon (bottom nav)
- [ ] Badge should show the count
- [ ] Open the chat → badge disappears
- [ ] Account 2 sends message → badge reappears

### Test 9: Online Status
- [ ] Have both accounts logged in
- [ ] Open chat between them
- [ ] Each should show "Online" under friend name in AppBar
- [ ] Should see green dot on friend's avatar in chat list
- [ ] Log out account 2
- [ ] Account 1 should see "Last seen 02:30 PM" (or time)
- [ ] Green dot should disappear from avatar

### Test 10: Date Dividers
- [ ] Send message today
- [ ] Go to device settings, change date to tomorrow
- [ ] Send another message
- [ ] Should see "Today" divider between old and new message
- [ ] (Or change back, send tomorrow, will show "Yesterday")

### Test 11: AppBar Buttons
- [ ] Tap video call button → "coming soon" snackbar
- [ ] Tap voice call button → "coming soon" snackbar
- [ ] Tap back button → return to Chat list

### Test 12: Input Bar Features
- [ ] Emoji button → "coming soon" snackbar
- [ ] Attachment button → "coming soon" snackbar
- [ ] Empty input field → shows mic button
- [ ] Text in field → shows send button
- [ ] Clear text → mic button returns

### Test 13: Keyboard Interaction
- [ ] Tap message field
- [ ] Keyboard should appear
- [ ] Input bar should push up with keyboard
- [ ] Type message, send
- [ ] Keyboard should close
- [ ] Should auto-scroll to new message

### Test 14: Special Messages
- [ ] Send empty message (should not work)
- [ ] Send message with emojis: "Hey! 👋🎉"
- [ ] Send message with line breaks (copy from Notes app)
- [ ] Send very long message (100+ characters)
- [ ] All should display correctly

### Test 15: Navigation
- [ ] From Chat tab, open a chat
- [ ] Go to Groups tab (chat stays open in background)
- [ ] Return to Chat tab → back at chat list
- [ ] Tap a chat → should open specific chat
- [ ] Tap back button → return to chat list

### Test 16: Multiple Users
- [ ] Have Account A chat with Account B
- [ ] Have Account A chat with Account C
- [ ] Chat list should show 2 separate conversations
- [ ] Each should have separate message history
- [ ] Switching between chats should show correct messages

### Test 17: Persistence
- [ ] Send message
- [ ] Force quit app (Settings → app → Force Stop)
- [ ] Reopen app
- [ ] Message should still be there
- [ ] Should be in correct position in conversation

### Test 18: Real-time Sync
- [ ] Open same chat on 2 devices/accounts
- [ ] Send message from device 1
- [ ] Message should appear instantly on device 2
- [ ] No need to refresh or reopen

---

## 🐛 Known Issues to Watch For

None currently - all core features working!

---

## 📊 Expected Firebase Structure

After testing, your Firebase should have:
```
chats/
  ├── uid1_uid2/
  │   ├── lastMessage: "Hi there!"
  │   ├── lastMessageTime: <timestamp>
  │   ├── participants: [uid1, uid2]
  │   ├── unread_uid1: 0
  │   ├── unread_uid2: 1
  │   └── messages/
  │       ├── msg1/
  │       │   ├── id: "msg1"
  │       │   ├── senderId: "uid1"
  │       │   ├── receiverId: "uid2"
  │       │   ├── message: "Hello!"
  │       │   ├── timestamp: <timestamp>
  │       │   ├── isRead: true
  │       │   └── messageType: "text"
  │       └── msg2/
  │           └── ...
  └── uid3_uid4/
      └── ...
```

---

## 🔧 Troubleshooting

### Messages don't appear
- [ ] Check Firebase Firestore rules (allow reads/writes for participants)
- [ ] Verify both users are friends
- [ ] Check network connection
- [ ] Verify users are not blocked

### Unread count stuck
- [ ] Try closing and reopening app
- [ ] Check Firestore unread_* fields manually
- [ ] Verify markAsRead() is being called

### Real-time updates not working
- [ ] Check internet connection
- [ ] Verify Firestore rules allow read access
- [ ] Check Firebase console for errors
- [ ] Try hot restart of app

### Online status always shows
- [ ] Verify user.isActive field updates on login/logout
- [ ] Check setUserActive() calls in app initialization

---

## 📱 Test with Real Firebase Project

To test with your Firebase:

1. Make sure at least 2 test accounts exist
2. Add them as friends to each other
3. Test on 2 different devices or emulators
4. Monitor Firebase console for real-time updates
5. Check Firestore database to see created documents

---

## ✅ Sign-Off Checklist

After testing all 18 tests:
- [ ] All messages appear in real-time
- [ ] Chat history persists correctly
- [ ] Unread badges work correctly
- [ ] Navigation works smoothly
- [ ] Online status updates
- [ ] Date dividers display correctly
- [ ] No crashes or errors
- [ ] Search filtering works
- [ ] Multiple conversations work independently
- [ ] Firebase structure looks correct

---

## 🎯 Next: Add Security Rules

Once testing is complete, add these Firestore security rules:

```typescript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Chat rooms
    match /chats/{chatId} {
      allow read: if request.auth.uid in resource.data.participants;
      allow update: if request.auth.uid in resource.data.participants;
      allow create: if request.auth.uid in request.resource.data.participants;
      
      // Messages within chat
      match /messages/{messageId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if request.auth.uid == request.resource.data.senderId;
        allow update: if resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

---

## 📞 Support

If something doesn't work:
1. Check the console logs
2. Verify Firestore structure matches expected format
3. Ensure both users are authenticated
4. Check Firebase project settings
5. Review security rules

Happy Testing! 🚀
