//
//  ChatViewController.m
//  ChatGPT - - - Project
//
//  Created by Mali 357 on 13/08/23.
//  Copyright (c) 2023 Mali357. All rights reserved.
//


//UITextView code is from https://github.com/ToruTheRedFox/iOS-Discord-Classic
//^^^^^^^pill shaped thing on toolbar for the not so smart people ^^^^^^^^^^^^
//not the actual content aka mainview

#import "ChatViewController.h"
#import "TRMalleableFrameView.h"

@interface ChatViewController () <UITextViewDelegate, NSURLConnectionDelegate>

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, assign) BOOL isKeyboardVisible;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isKeyboardVisible = NO;
    
    self.inputField.delegate = self;
    
    self.responseData = [[NSMutableData alloc] init];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.inputField setDelegate:self];
    
    //self.inputFieldPlaceholder.text = [NSString stringWithFormat:@"Topic: %@", self.navigationItem.title];
    self.inputFieldPlaceholder.hidden = YES;
    
    [[self.insetShadow layer] setMasksToBounds:YES];
    [[self.insetShadow layer] setCornerRadius:16.0f];
    [[self.insetShadow layer] setBorderColor:[UIColor whiteColor].CGColor];
    [[self.insetShadow layer] setBorderWidth:1.0f];
    [[self.insetShadow layer] setShadowColor:[UIColor blackColor].CGColor];
    [[self.insetShadow layer] setShadowOffset:CGSizeMake(0, 0)];
    [[self.insetShadow layer] setShadowOpacity:1];
    [[self.insetShadow layer] setShadowRadius:4.0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self tryToWriteHistoryOhMyGod:self.chatTextView.text];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
}
//this saves chat cotnents to txt file
- (void)tryToWriteHistoryOhMyGod:(NSString *)conversation {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSInteger lastConversationNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastConversationNumber"];
    lastConversationNumber++;
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filename = [NSString stringWithFormat:@"%ld.txt", (long)lastConversationNumber];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    //fuck this shit i hate this
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentsDirectory]) {
        [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:lastConversationNumber forKey:@"lastConversationNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [conversation writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)YourKeyProbablyExpired {
    NSString *errorMessage = @"Your API key is missing, please specify it in the settings page. If the AI doesn't respond to your key despite you having a solid internet connection, your key may've expired.";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alertView show];
}

- (void)performRequest {
    NSString *gptprompt = [[NSUserDefaults standardUserDefaults] objectForKey:@"gptPrompt"];
    NSString *modelType = [[NSUserDefaults standardUserDefaults] objectForKey:@"AIModel"];
    NSString *message = self.inputField.text;
    NSString *apiEndpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiEndpoint"];
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
    NSString *userNickname = [[NSUserDefaults standardUserDefaults] objectForKey:@"userNick"];
    //NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"User-Agent"]; //soon
    NSString *conversationHistory = [[NSUserDefaults standardUserDefaults] objectForKey:@"conversationHistory"];
    
    if (apiKey.length == 0) {
        [self YourKeyProbablyExpired];
        return;
    }
    
    if (message.length > 0) {
        NSString *previousChat = self.chatTextView.text;
        
        // Append an empty line between the user's message and the previous conversation
        NSString *separator = @"\n\n";
        
        if (previousChat.length > 0) {
            NSString *lastCharacter = [previousChat substringFromIndex:previousChat.length - 1];
            
            // Check if the last character is already a newline, if not, append the separator
            if (![lastCharacter isEqualToString:@"\n"]) {
                self.chatTextView.text = [NSString stringWithFormat:@"%@%@%@: %@", previousChat, separator, userNickname, message];
            } else {
                self.chatTextView.text = [NSString stringWithFormat:@"%@%@: %@", previousChat, userNickname, message];
            }
        } else {
            self.chatTextView.text = [NSString stringWithFormat:@"%@: %@", userNickname, message];
        }
        
        self.inputField.text = @"";
        
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSURL *url = [NSURL URLWithString:apiEndpoint];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

        // HTTP Request headers
        //[request setValue:[NSString stringWithFormat:@"%@", userAgent] forHTTPHeaderField:@"User-Agent"];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
        
        NSMutableArray *messagesArray = [NSMutableArray arrayWithArray:@[
                                                                         @{
                                                                             @"role": @"user",
                                                                             @"content": [gptprompt stringByAppendingString:message]
                                                                             }
                                                                         ]];
        
        if (conversationHistory && ![conversationHistory isKindOfClass:[NSNull class]]) {
            [messagesArray addObject:@{
                                       @"role": @"assistant",
                                       @"content": conversationHistory
                                       }];
        }
        
        NSMutableDictionary *bodyData = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"model": [NSString stringWithFormat:@"%@", modelType],
                                                                                        @"messages": messagesArray
                                                                                        }];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyData options:0 error:nil];
        [request setHTTPBody:jsonData];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [connection start];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:nil];
    NSLog(@"Response received");
    
    NSArray *choices = [responseDictionary objectForKey:@"choices"];
    NSString *assistantNick = [[NSUserDefaults standardUserDefaults] objectForKey:@"assistantNick"];
    
    if ([choices count] > 0) {
        NSDictionary *choice = [choices objectAtIndex:0];
        NSDictionary *message = [choice objectForKey:@"message"];
        id contentObject = [message objectForKey:@"content"];
        
        if (contentObject && ![contentObject isKindOfClass:[NSNull class]]) {
            NSString *assistantReply = [NSString stringWithFormat:@"%@", contentObject];
            NSString *separator = @"\n\n";
            NSString *updatedConversation;
            
            if (self.chatTextView.text.length > 0) {
                NSString *lastCharacter = [self.chatTextView.text substringFromIndex:self.chatTextView.text.length - 1];
                
                if (![lastCharacter isEqualToString:@"\n"]) {
                    updatedConversation = [NSString stringWithFormat:@"%@%@%@: %@", self.chatTextView.text, separator, assistantNick, assistantReply];
                } else {
                    updatedConversation = [NSString stringWithFormat:@"%@%@: %@", self.chatTextView.text, assistantNick, assistantReply];
                }
            } else {
                updatedConversation = [NSString stringWithFormat:@"%@: %@", assistantNick, assistantReply];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:assistantReply forKey:@"conversationHistory"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.chatTextView.text = updatedConversation;
            NSRange bottomRange = NSMakeRange(self.chatTextView.text.length, 1);
            [self.chatTextView scrollRangeToVisible:bottomRange];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	
	//thx to Pierre Legrain
	//http://pyl.io/2015/08/17/animating-in-sync-with-ios-keyboard/
	
	int keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTextView setHeight:self.view.height - keyboardHeight - self.toolbar.height];
	[self.toolbar setY:self.view.height - keyboardHeight - self.toolbar.height];
	[UIView commitAnimations];
	
	
	if(self.viewingPresentTime)
		[self.chatTextView setContentOffset:CGPointMake(0, self.chatTextView.contentSize.height - self.chatTextView.frame.size.height) animated:NO];
}


- (void)keyboardWillHide:(NSNotification *)notification {
	
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTextView setHeight:self.view.height - self.toolbar.height];
	[self.toolbar setY:self.view.height - self.toolbar.height];
	[UIView commitAnimations];
}


//button actions

- (BOOL)textViewShouldReturn:(UITextView *)textView {
    [textView resignFirstResponder]; // make th keyboard go down when pressed return
    return YES;
}

//this sends the inputted contents of inputTextView (just check void(sendMessageTChatGPTAPI) to see what it exactly does.
- (IBAction)sendButtonTapped:(id)sender {
    [self performRequest];
    
    if(![self.inputField.text isEqual: @""]){
        
		[self.inputField setText:@""];
        self.inputFieldPlaceholder.hidden = NO;
	}else
		[self.inputField resignFirstResponder];
	
	if(self.viewingPresentTime)
		[self.chatTextView setContentOffset:CGPointMake(0, self.chatTextView.contentSize.height - self.chatTextView.frame.size.height) animated:YES];
}


//ok
- (IBAction)exportButtonTapped:(id)sender {
    NSString *textContent = self.chatTextView.text;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"sharedConversation.txt"];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    NSError *error = nil;
    [textContent writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    
    //open activityviewcontroller
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}
//mail

-(IBAction)killYourSelf:(id)sender {
    
}

- (NSString *)getCurrentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    return timestamp;
}

@end