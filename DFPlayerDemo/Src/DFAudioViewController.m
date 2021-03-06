//
//  DFAudioViewController.m
//  DFPlayerDemo
//
//  Created by HDF on 2017/10/7.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFAudioViewController.h"
#import "DFPlayer.h"
#import "YourDataModel.h"
#import "DFMacro.h"
#import "NSObject+Alert.h"
#import "UIImage+Blur.h"
static NSString *cellId = @"cellId";
#define topH SCREEN_HEIGHT - self.tabBarController.tabBar.frame.size.height-CountHeight(200)
@interface DFAudioViewController ()
<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,DFPlayerDelegate,DFPlayerDataSource>
@property (nonatomic, strong) UIScrollView      *scrollView;
@property (nonatomic, strong) UITableView       *tableView;
@property (nonatomic, strong) UIImageView       *backgroundImageView;

@property (nonatomic, strong) NSMutableArray    *dataArray;
@property (nonatomic, strong) NSMutableArray    *df_ModelArray;
@property (nonatomic, strong) NSArray           *addArray;//模拟添加数据
@property (nonatomic, assign) NSInteger         addIndex;//添加音频数组标识
@property (nonatomic, assign) BOOL              stopUpdate;
@end

@implementation DFAudioViewController
#pragma mark - 加载视图
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加音频" style:(UIBarButtonItemStylePlain) target:self action:@selector(addSongAction)];
    self.navigationItem.rightBarButtonItem.tintColor = HDFGreenColor;

    self.addIndex = 0;
    [self initBackGroundView];
    [self initDFPlayer];
    [self initUI];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self tableViewReloadData];
}

#pragma mark - UI
- (void)initBackGroundView{
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.frame = [UIScreen mainScreen].bounds;
    self.backgroundImageView.backgroundColor = [UIColor whiteColor];
    self.backgroundImageView.image = [UIImage imageNamed:@"default_bg.jpg"];
    self.backgroundImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.backgroundImageView];
    //这里使用iOS8以后才能使用的虚化方法
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    effectView.frame = self.backgroundImageView.frame;
    [self.backgroundImageView addSubview:effectView];
}
- (void)initUI{
    CGFloat H = topH - CountHeight(10);
    CGRect rect = CGRectMake( 0, 0, SCREEN_WIDTH, H);
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.frame = rect;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, H);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.tableView              = [[UITableView alloc] init];
    self.tableView.frame        = rect;
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
    self.tableView.rowHeight    = CountHeight(100);
    [self.scrollView addSubview:self.tableView];
    
    //歌词tableview
    UITableView *lyricsTableView =
    [[DFPlayerControlManager shareInstance] df_lyricTableViewWithFrame:(CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, H))
                                                          contentInset:UIEdgeInsetsMake((H-CountHeight(90))/2, 0, (H-CountHeight(90))/2, 0)
                                                         cellRowHeight:CountHeight(90)
                                                   cellBackgroundColor:[UIColor clearColor]
                                     currentLineLrcForegroundTextColor:HDFGreenColor
                                     currentLineLrcBackgroundTextColor:[UIColor whiteColor]
                                       otherLineLrcBackgroundTextColor:[UIColor whiteColor]
                                                    currentLineLrcFont:HDFSystemFontOfSize(34)
                                                      otherLineLrcFont:HDFSystemFontOfSize(29)
                                                             superView:self.scrollView
                                                            clickBlock:^(NSIndexPath * _Nullable indexpath) {

                                                                 }];
    lyricsTableView.backgroundColor = [UIColor clearColor];
}
#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
    }
    YourDataModel *model = self.dataArray[indexPath.row];
    NSString *audioType = @"网络音频";
    if (![model.yourUrl hasPrefix:@"http"]) {audioType = @"本地音频";}
    cell.textLabel.text = [NSString stringWithFormat:@"%ld--%@-%@(%@)",(long)indexPath.row,audioType,model.yourName,model.yourSinger];
    NSURL *url = [self translateIllegalCharacterWtihUrlStr:model.yourUrl];
    if ([DFPlayer df_playerCheckIsCachedWithAudioUrl:url]) {
        cell.tintColor = HDFGreenColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.detailTextLabel.hidden = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.df_ModelArray.count > indexPath.row) {
        DFPlayerModel *model = self.df_ModelArray[indexPath.row];
        [[DFPlayer shareInstance] df_playerPlayWithAudioId:model.audioId];
        [self.scrollView setContentOffset:(CGPointMake(SCREEN_WIDTH, 0)) animated:YES];
    }
}
#pragma mark - 初始化DFPlayer
- (void)initDFPlayer{
    [[DFPlayer shareInstance] df_initPlayerWithUserId:nil];
    [DFPlayer shareInstance].dataSource  = self;
    [DFPlayer shareInstance].delegate    = self;
    [DFPlayer shareInstance].category    = DFPlayerAudioSessionCategoryPlayback;
    [DFPlayer shareInstance].isObserveWWAN = YES;
//    [DFPlayer shareInstance].type = DFPlayerTypeOnlyOnce;//DFPLayer默认单曲循环。
    [DFPlayer shareInstance].isObservePreviousAudioModel = YES;
    [[DFPlayer shareInstance] df_reloadData];//必须在传入数据源后调用（类似UITableView的reloadData）
    
    CGRect buffRect = CGRectMake(CountWidth(104), topH+CountHeight(28), CountWidth(542), CountHeight(4));
    CGRect proRect  = CGRectMake(CountWidth(104), topH+CountHeight(10), CountWidth(542), CountHeight(40));
    CGRect currRect = CGRectMake(CountWidth(10), topH+CountHeight(10), CountWidth(90), CountHeight(40));
    CGRect totaRect = CGRectMake(SCREEN_WIDTH-CountWidth(100), topH+CountHeight(10), CountWidth(90), CountHeight(40));
    CGRect playRect = CGRectMake(CountWidth(320), topH+CountHeight(70), CountWidth(110), CountWidth(110));
    CGRect nextRext = CGRectMake(CountWidth(490), topH+CountHeight(84), CountWidth(80), CountWidth(80));
    CGRect lastRect = CGRectMake(CountWidth(180), topH+CountHeight(84), CountWidth(80), CountWidth(80));
    CGRect typeRect = CGRectMake(CountWidth(40), topH+CountHeight(100), CountWidth(63), CountHeight(45));
    
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];
    //缓冲条
    [manager df_bufferProgressViewWithFrame:buffRect trackTintColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] progressTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5] superView:self.backgroundImageView];
    //进度条
    [manager df_sliderWithFrame:proRect minimumTrackTintColor:HDFGreenColor maximumTrackTintColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.0] trackHeight:CountHeight(4) thumbSize:(CGSizeMake(CountWidth(34), CountWidth(34))) superView:self.backgroundImageView];
    //当前时间
    UILabel *curLabel = [manager df_currentTimeLabelWithFrame:currRect superView:self.backgroundImageView];
    curLabel.textColor = [UIColor whiteColor];
    //总时间
    UILabel *totLabel = [manager df_totalTimeLabelWithFrame:totaRect superView:self.backgroundImageView];
    totLabel.textColor = [UIColor whiteColor];

    //播放模式按钮
    [manager df_typeControlBtnWithFrame:typeRect superView:self.backgroundImageView block:nil];
    //播放暂停按钮
    [manager df_playPauseBtnWithFrame:playRect superView:self.backgroundImageView block:nil];
    //下一首按钮
    [manager df_nextAudioBtnWithFrame:nextRext superView:self.backgroundImageView block:nil];
    //上一首按钮
    [manager df_lastAudioBtnWithFrame:lastRect superView:self.backgroundImageView block:nil];
}

#pragma mark - DFPLayer dataSource
- (NSArray<DFPlayerModel *> *)df_playerModelArray{
    if (_df_ModelArray.count == 0) {
        _df_ModelArray = [NSMutableArray array];
    }else{
        [_df_ModelArray removeAllObjects];
    }
    for (int i = 0; i < self.dataArray.count; i++) {
        YourDataModel *yourModel    = self.dataArray[i];
        DFPlayerModel *model        = [[DFPlayerModel alloc] init];
        model.audioId               = i;//****重要。AudioId从0开始，仅标识当前音频在数组中的位置。
        if ([yourModel.yourUrl hasPrefix:@"http"]) {//网络音频
            model.audioUrl              = [self translateIllegalCharacterWtihUrlStr:yourModel.yourUrl];
        }else{//本地音频
            NSString *path = [[NSBundle mainBundle] pathForResource:yourModel.yourUrl ofType:@""];
            if (path) {model.audioUrl = [NSURL fileURLWithPath:path];}
        }
        [_df_ModelArray addObject:model];
    }
    return self.df_ModelArray;
}
- (DFPlayerInfoModel *)df_playerAudioInfoModel:(DFPlayer *)player{
    YourDataModel *yourModel        = self.dataArray[player.currentAudioModel.audioId];
    DFPlayerInfoModel *infoModel    = [[DFPlayerInfoModel alloc] init];
    //音频名 歌手 专辑名
    infoModel.audioName     = yourModel.yourName;
    infoModel.audioSinger   = yourModel.yourSinger;
    infoModel.audioAlbum    = yourModel.yourAlbum;
    //歌词
    NSString *lyricPath     = [[NSBundle mainBundle] pathForResource:yourModel.yourLyric ofType:nil];
    infoModel.audioLyric    = [NSString stringWithContentsOfFile:lyricPath encoding:NSUTF8StringEncoding error:nil];
    //配图
    NSURL *imageUrl         = [NSURL URLWithString:yourModel.yourImage];
    NSData *imageData       = [NSData dataWithContentsOfURL:imageUrl];
    infoModel.audioImage    = [UIImage imageWithData: imageData];
    return infoModel;
}
#pragma mark - DFPlayer delegate
//加入播放队列
- (void)df_playerAudioWillAddToPlayQueue:(DFPlayer *)player{
    [self tableViewReloadData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *audioImage = player.currentAudioInfoModel.audioImage;
        if (audioImage) {
            CGFloat imgW = audioImage.size.height*SCREEN_WIDTH/SCREEN_HEIGHT;
            CGRect imgRect = CGRectMake((audioImage.size.width-imgW)/2, 0, imgW, audioImage.size.height);
            audioImage = [audioImage getSubImage:imgRect];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *audioName = player.currentAudioInfoModel.audioName;
            self.navigationItem.title = [NSString stringWithFormat:@"当前音频：%@",audioName];
            self.backgroundImageView.image = audioImage;
        });
    });
}
//网络状态监测代理
- (void)df_playerNetworkDidChangeToWWAN:(DFPlayer *)player{
    [self showAlertWithTitle:@"继续播放将产生流量费用" message:nil noBlock:nil yseBlock:^{
        [DFPlayer shareInstance].isObserveWWAN = NO;
        [[DFPlayer shareInstance] df_playerPlayWithAudioId:player.currentAudioModel.audioId];
    }];
}
//缓冲进度代理
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress totalTime:(CGFloat)totalTime{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:player.currentAudioModel.audioId
                                                inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"正在缓冲%lf",bufferProgress];
    cell.detailTextLabel.hidden = NO;
}
//播放进度代理
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:player.currentAudioModel.audioId
                                                inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"当前进度%lf--当前时间%.0f--总时长%.0f",progress,currentTime,totalTime];
    cell.detailTextLabel.hidden = NO;
}
//缓存情况代理
- (void)df_player:(DFPlayer *)player isCached:(BOOL)isCached{
    if (isCached) {[self tableViewReloadData];}
}
//错误信息代理
- (void)df_player:(DFPlayer *)player didFailWithErrorMessage:(NSString *)errorMessage{
    [self showAlertWithTitle:errorMessage message:nil yesBlock:nil];
}

#pragma mark - 从plist中加载音频数据
- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
        NSString *path1 = [[NSBundle mainBundle] pathForResource:@"AudioData" ofType:@"plist"];
        NSMutableArray *arr = [[NSMutableArray alloc] initWithContentsOfFile:path1];
        for (int tag = 0; tag < 1; tag++) {
            for (int i = 0; i < arr.count; i++) {
                YourDataModel *model = [self setDataModelWithDic:arr[i]];
                [_dataArray addObject:model];
            }
        }
    }
    return _dataArray;
}
- (YourDataModel *)setDataModelWithDic:(NSDictionary *)dic{
    YourDataModel *model = [[YourDataModel alloc] init];
    model.yourUrl       = [dic valueForKey:@"audioUrl"];
    model.yourName      = [dic valueForKey:@"audioName"];
    model.yourSinger    = [dic valueForKey:@"audioSinger"];
    model.yourAlbum     = [dic valueForKey:@"audioAlbum"];
    model.yourImage     = [dic valueForKey:@"audioImage"];
    model.yourLyric     = [dic valueForKey:@"audioLyric"];
    return model;
}
- (NSArray *)addArray{
    if (_addArray == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"addAudio" ofType:@"plist"];
        NSMutableArray *addData = [[NSMutableArray alloc] initWithContentsOfFile:path];
        _addArray = [NSArray arrayWithArray:addData];
    }
    return _addArray;
}

#pragma mark - scrolleview delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.x >= SCREEN_WIDTH) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"暂停恢复" style:(UIBarButtonItemStylePlain) target:self action:@selector(stopResumeBtnAction)];
        self.navigationItem.leftBarButtonItem.tintColor = HDFGreenColor;
    }else{
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem new];
    }
}
- (void)stopResumeBtnAction{
    if (self.stopUpdate) {
        [[DFPlayerControlManager shareInstance] df_playerLyricTableviewResumeUpdate];
        self.stopUpdate = NO;
    }else{
        [[DFPlayerControlManager shareInstance] df_playerLyricTableviewStopUpdate];
        self.stopUpdate = YES;
    }
}
#pragma mark - action
- (void)addSongAction{
    if (self.addIndex >= self.addArray.count) {
        [self showAlertWithTitle:@"添加完毕，已无更多音频" message:nil yesBlock:nil];
        return;
    }
    YourDataModel *yourModel = [self setDataModelWithDic:self.addArray[self.addIndex]];
    [self.dataArray insertObject:yourModel atIndex:0];//这里将数据加到第一个
    [self tableViewReloadData];
    self.addIndex++;
    //更新DFPlayer的音频数据
    [[DFPlayer shareInstance] df_reloadData];
}
- (NSURL *)translateIllegalCharacterWtihUrlStr:(NSString *)yourUrl{
    //如果链接中存在中文或某些特殊字符，需要通过以下代码转译
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)yourUrl, (CFStringRef)@"!NULL,'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
    //        NSString *str = [ss stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:encodedString];
}
- (void)tableViewReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
