/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SLViewController.h"
#import "PennAppsAppDelegate.h"
#import "JTRevealSidebarV2Delegate.h"
#import "UINavigationItem+JTRevealSidebarV2.h"
#import "UIViewController+JTRevealSidebarV2.h"
#import "SidebarViewController.h"
#import "FilterViewController.h"
#import "NSString+NSString_URLEncode.h"

@interface SLViewController ()<JTRevealSidebarV2Delegate>

@property (strong, nonatomic) IBOutlet UIButton *buttonLoginLogout;
@property (strong, nonatomic) IBOutlet UITextView *textNoteOrLink;
@property IBOutlet UITextField* status;
@property UIButton *updateStatus;
@property UIButton *updateFilter;
@property NSString* token;
@property IBOutlet UIWebView *webDisplay;
@property SidebarViewController* leftSidebarViewController;
@property UIWebView *webwebview;

- (IBAction)buttonClickHandler:(id)sender;
- (void)updateView;

@end

@implementation SLViewController

@synthesize textNoteOrLink = _textNoteOrLink;
@synthesize buttonLoginLogout = _buttonLoginLogout;

static SLViewController * _sharedInstance = nil;
+ (SLViewController *)sharedSLViewController
{
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)viewDidLoad {    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self updateView];
    
    self.navigationItem.revealSidebarDelegate = self;
    
    PennAppsAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (!appDelegate.session.isOpen) {
        // create a fresh session object
        appDelegate.session = [[FBSession alloc] init];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
                                                             FBSessionState status, 
                                                             NSError *error) {
                // we recurse here, in order to update buttons and labels
                [self updateView];
            }];
        }
    }
}

// FBSample logic
// main helper method to update the UI to reflect the current state of the session.
- (void)updateView {
    // get the app delegate, so that we can reference the session property
   PennAppsAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (appDelegate.session.isOpen) {
        // valid account UI is shown whenever the session is open
        [self.buttonLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
        
        
        [self.textNoteOrLink setText:[NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@",
                                      appDelegate.session.accessTokenData.accessToken]];
        
        [self.textNoteOrLink setText:@""];
        
        
        self.updateFilter.hidden=NO;
        self.updateFilter = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.updateFilter addTarget:self
                              action:@selector(transitionToFilter:)
                    forControlEvents:UIControlEventTouchDown];
        [self.updateFilter setTitle:@"+" forState:UIControlStateNormal];
        self.updateFilter.frame = CGRectMake(275, 48, 40, 40);
        //[self.view addSubview:self.updateFilter];
        
        
        self.status.hidden=NO;
        self.status = [[UITextField alloc] initWithFrame:CGRectMake(10, 48, 300, 40)];
        self.status.borderStyle = UITextBorderStyleRoundedRect;
        self.status.font = [UIFont systemFontOfSize:15];
        self.status.placeholder = @"Insert status here...";
        self.status.autocorrectionType = UITextAutocorrectionTypeNo;
        self.status.keyboardType = UIKeyboardTypeDefault;
        self.status.returnKeyType = UIReturnKeyDone;
        self.status.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.status.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.status.delegate = self;
        [self.view addSubview:self.status];
        
        self.updateStatus.hidden=NO;
        self.updateStatus = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.updateStatus addTarget:self
                   action:@selector(updateStatusMethod:)
         forControlEvents:UIControlEventTouchDown];
        [self.updateStatus setTitle:@"Update" forState:UIControlStateNormal];
        self.updateStatus.frame = CGRectMake(210, 48, 100, 40);
        //[self.view addSubview:self.updateStatus];
        
      //  self.token = appDelegate.session.accessTokenData.accessToken;
      //  NSLog(@"Access: %@",appDelegate.session.accessTokenData.accessToken);
 
     
    }

    else {
        self.status.hidden=YES;
        self.updateStatus.hidden=YES;
        // login-needed account UI is shown whenever the session is closed
        [self.buttonLoginLogout setTitle:@"Log in" forState:UIControlStateNormal];        
        [self.textNoteOrLink setText:@""];        
    }

}

// FBSample logic
// handler for button click, logs sessions in or out
- (IBAction)buttonClickHandler:(id)sender {
    // get the app delegate so that we can access the session property
    PennAppsAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    // this button's job is to flip-flop the session from open to closed
    if (appDelegate.session.isOpen) {
        // if a user logs out explicitly, we delete any cached token information, and next
        // time they run the applicaiton they will be presented with log in UX again; most
        // users will simply close the app or switch away, without logging out; this will
        // cause the implicit cached-token login to occur on next launch of the application
        [appDelegate.session closeAndClearTokenInformation];
        
    } else {
        if (appDelegate.session.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            /*
            NSArray *permissions =
            [NSArray arrayWithObjects:@"email",@"friends_likes",@"friends_status",@"friends_subscriptions",@"friends_interests",@"friends_online_presence", nil];
             */
           appDelegate.session = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        [appDelegate.session openWithCompletionHandler:^(FBSession *session, 
                                                         FBSessionState status,
                                                         NSError *error) {
            // and here we make sure to update our UX according to the new session state
            [self updateView];
        }];
    } 
}

-(NSDictionary*)postRequest:(NSString*)string{
    NSError *error;
    /*
    NSDictionary *dic =  [[NSDictionary alloc] initWithObjectsAndKeys:
                          dict, @"feed",
                          nil];
     */
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:string
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    }else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"json information: %@",jsonString);
    }
    NSURL *yourURL = [NSURL URLWithString:@"http://ec2-54-200-10-216.us-west-2.compute.amazonaws.com:8000/post_mobile"];
    NSMutableURLRequest *yourRequest = [NSMutableURLRequest requestWithURL:yourURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:5.0];
    [yourRequest setHTTPMethod:@"POST"];
    [yourRequest setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [yourRequest setHTTPBody:jsonData];
    
    NSError *requestError;
    NSHTTPURLResponse *urlResponse = nil;
    
    NSData *response = [NSURLConnection sendSynchronousRequest:yourRequest returningResponse:&urlResponse error:&requestError];
    NSLog(@"Status code: %i",urlResponse.statusCode);
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"VAISHAK: %@",responseString);
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
    return dictionary;
}


-(void)updateStatusMethod:(id)sender{
    //dismiss keyboard
    [self.status resignFirstResponder];
    
    /*
    NSString* relevant = [NSString stringWithFormat:@"https://graph.facebook.com/%@/feed?limit=1&fields=likes,message,shares&access_token=%@",
                          self.status.text,self.token];
    
    NSURL *yourURL = [NSURL URLWithString:relevant];
    NSMutableURLRequest *yourRequest = [NSMutableURLRequest requestWithURL:yourURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:5.0];
    [yourRequest setHTTPMethod:@"GET"];
    [yourRequest setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    
    NSError *requestError;
    NSError *error;
    NSHTTPURLResponse *urlResponse = nil;
    
    NSData *response = [NSURLConnection sendSynchronousRequest:yourRequest returningResponse:&urlResponse error:&requestError];
    NSString *string = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
    //NSLog(@"RESULT: %@",dictionary);
    [self postRequest:string]; //get specifics from VSHAQ (he will return HTML)
     */
    
    //I should do a GET request with the status
    //Launch url in webview
    
    NSString *encodedString = [self.status.text urlEncode];
    NSLog(@"encoded string: %@",encodedString);
    
    NSString* url = [NSString stringWithFormat:@"http://ec2-54-200-10-216.us-west-2.compute.amazonaws.com:8000/fb1?status=%@",encodedString];
    
        
    [self.webwebview removeFromSuperview];
    self.webwebview = [[UIWebView alloc] initWithFrame:CGRectMake(10, 110, 300, 300)];
    /*
    NSURL *nsurl=[NSURL URLWithString:url];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [self.webwebview loadRequest:nsrequest]; //TEST URL CORE
     */
    self.webwebview.scrollView.scrollEnabled=NO;
    self.webwebview.scrollView.bounces = NO;
    [self.webwebview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"playa" ofType:@"html"]isDirectory:NO]]]; //TEST HTML CORE
    [self.view addSubview:self.webwebview];

}


-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField==self.status) {
        NSLog(@"done editing eh");
        [self updateStatusMethod:nil];
        [textField resignFirstResponder];
    }
    return YES;
}

-(IBAction)moreButtonAction:(id)sender{
    NSLog(@"Invisi button clicked");
    FilterViewController *filterViewControllerInstance = [[FilterViewController alloc]  initWithNibName:@"FilterViewController" bundle:nil];
    [self presentViewController:filterViewControllerInstance animated:YES completion:NULL];
    NSLog(@"Transition to filter");
}

#pragma mark Template generated code

- (void)viewDidUnload
{
    self.buttonLoginLogout = nil;
    self.textNoteOrLink = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark -

@end
