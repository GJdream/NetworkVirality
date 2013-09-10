//
//  FilterViewController.m
//  PennApps
//
//  Created by Sunny Shah on 9/7/13.
//  Copyright (c) 2013 Sunny Shah. All rights reserved.
//

#import "FilterViewController.h"
#import "SLViewController.h"
#import "PennAppsAppDelegate.h"

@interface FilterViewController ()
    @property UIButton *backButton;
@property NSString*token;
@property UIButton *saveButton;
@end

@implementation FilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.status1.delegate=self;
    self.pageName1.delegate=self;

    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backButton addTarget:self
                          action:@selector(transitionBack:)
                forControlEvents:UIControlEventTouchDown];
    [self.backButton setTitle:@"<--" forState:UIControlStateNormal];
    self.backButton.frame = CGRectMake(10, 10, 40, 40);
    [self.view addSubview:self.backButton];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.saveButton addTarget:self
                        action:@selector(saveAction:)
              forControlEvents:UIControlEventTouchDown];
    [self.saveButton setTitle:@"Update" forState:UIControlStateNormal];
    self.saveButton.frame = CGRectMake(10, 400, 300, 40);
   // [self.view addSubview:self.saveButton];

}

-(void)transitionBack:(id)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"Transition back");
}

-(void)saveAction:(id)sender{
    NSLog(@"Saving");
    //dismiss keyboard
    [self.status1 resignFirstResponder];
    PennAppsAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    NSString* relevant = [NSString stringWithFormat:@"https://graph.facebook.com/%@/feed?limit=1&fields=likes,message,shares&access_token=%@",
                          self.status1.text,appDelegate.session.accessTokenData.accessToken];
    
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
    [self dismissViewControllerAnimated:YES completion:NULL]; //go back sucka
}

-(NSDictionary*)postRequest:(NSString*)string{
    NSError *error;
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

/*
-(NSDictionary*)postRequest:(NSString*)string{
    NSError *error;
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
 */

//Textfield editing
#pragma mark TextFieldDelegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField==self.status1) {
        [self performAnimations:3];
    }else if(textField==self.pageName1){
        [self performAnimations:3];
    }
}

-(void)performAnimations:(float)bywhat
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.view.frame=CGRectMake(self.view.frame.origin.x, (self.view.frame.origin.y -bywhat), self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.view.frame=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField==self.status1) {
        [self.pageName1 becomeFirstResponder];
    }else{
        [textField resignFirstResponder];
    }
    return YES;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
