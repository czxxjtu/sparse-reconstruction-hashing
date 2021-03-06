function evaluation_info =evaluate_CH_ext(Xtraining,Xtest,KNN_info,Param)

tmp_T=cputime;
Param = trainCH_ext(Xtraining, Param);
traintime=cputime-tmp_T;
evaluation_info.trainT=traintime;

%%
ntest=size(Xtest,1);
ntraining=size(Xtraining,1);
L=size(Param.A,2);
II=1:ntraining;

tmp_T=cputime;
for j=1:L
    B_tst{j} = compressCH( Xtest, Param.A{j}, Param.B{j} );
    B_trn{j} = compressCH( Xtraining, Param.A{j}, Param.B{j} );
    Mask{j}=setdiff(II,Param.Mask{j});
    SizeL(j)=length(Param.Mask{j});
end
compressiontime=cputime-tmp_T;
evaluation_info.compressT=compressiontime;

%%
RR=0;PP=0;
block_size=Param.block_size;
block_num=ntest/block_size;
for i_block=1:block_num
    fprintf('%d ', i_block);
    D=zeros(block_size,ntraining,'uint8');
    D=D+inf;
    D2=zeros(block_size,ntraining,'single');
    ibase=(i_block-1)*block_size;
    imax=min(i_block*block_size, ntest);
    BlockIdx=ibase+1:imax;
    for j=1:L
        Dhamm = hammingDist(B_tst{j}(BlockIdx,:), B_trn{j});
        if(Param.doMask)
            Dhamm(:,Mask{j})=inf;
        end
        D=min(Dhamm,D);
        D2=D2+single(Dhamm);
    end
    D2=D2/(max(max(D2))+1);
    D2=single(D)+D2;
    [foo, Rank] = sort(D2, 2,'ascend');
      
    Rank=single(Rank);
    if(iscell(KNN_info.knn_p2))
        trueRank=KNN_info.knn_p2(BlockIdx);
        if(strcmp('ranking', Param.searchtype))
            eva_info = eva_ranking1(Rank, trueRank);
        else
            eva_info = eva_lookup1(Rank, trueRank, foo );
        end
    else
        trueRank=KNN_info.knn_p2(BlockIdx,:);
        if(strcmp('ranking', Param.searchtype))
            eva_info = eva_ranking(Rank, trueRank);
        else
            eva_info = eva_lookup(Rank, trueRank, foo );
        end
    end
    
%     Ri(i_block,:)=eva_info.recall;
%     Pi(i_block,:)=eva_info.precision;
%     Mi(i_block,:)=eva_info.M_set;
    
    RR=RR+eva_info.recall;
    PP=PP+eva_info.precision;
end

% evaluation_info.recall=mean(Ri);
% evaluation_info.precision=mean(Pi);
% evaluation_info.M_set=mean(Mi);
% DhammCH=D;
% save('.\DhammCH.mat','DhammCH'); 
evaluation_info.recall=RR/block_num;
evaluation_info.precision=PP/block_num;
evaluation_info.M_set=eva_info.M_set;
evaluation_info.SizeL=SizeL;