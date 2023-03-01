module Main where

import           Control.Concurrent.Async   (mapConcurrently)
import           Control.Concurrent.MVar    (MVar, modifyMVar_, newMVar, readMVar)
import           Control.Exception          (try)
import           Control.Monad              (forM_, when)
import           Data.ByteString.Lazy.Char8 (unpack)
import           Data.Time.Clock
import           Network.HTTP.Simple
import           System.Timeout             (timeout)
import           Text.Printf                (printf)

urlSource = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/3db61fe72e1ce6854faa025298bf4cdfd2b2f250/100-popular-urls.txt"
seperator = replicate 80 '-'

iterations = 10 :: Int
singleSource = True
verbose = True
timeoutMicros = 5000000

data ResultStatus = SUCCESS | ERROR | TIMEOUT
data Stats = Stats { successes :: Int, errors :: Int, timeouts :: Int, transferredBytes :: Int, sTime:: Float }
data TestResult = TestResult { url :: String, status :: ResultStatus, transferred :: Int, time :: Float }

prepUrls :: IO [String]
prepUrls =
	if singleSource
		then return [ "google.com/search?q=" ++ show i | i <- [1..100] ]
	else do
		fmap (lines . unpack . getResponseBody) (httpLBS =<< parseRequest urlSource)


getHttpResp :: String -> IO TestResult
getHttpResp url = do
	startTime <- getCurrentTime
	result <- timeout timeoutMicros $ try $ httpLBS =<< parseRequest ("http://www." ++ url)
	case result of
		Nothing -> do
			duration <- realToFrac . (`diffUTCTime` startTime) <$> getCurrentTime
			when verbose $ printf "TIMEOUT: %s. Time: %.2fs\n" url duration
			return (TestResult url TIMEOUT 0 duration)
		Just (Left e) -> do
			duration <- realToFrac . (`diffUTCTime` startTime) <$> getCurrentTime
			when verbose $ printf "ERROR: %s — %s. Time: %.2fs\n" url (show (e :: HttpException)) duration
			return (TestResult url ERROR 0 duration)
		Just (Right res) -> do
			let resLen = length (show (getResponseBody res))
			duration <- realToFrac . (`diffUTCTime` startTime) <$> getCurrentTime
			when verbose $ printf "%s — Transferred: %s Bytes. Time: %.2fs\n" url (show resLen) duration
			return (TestResult url SUCCESS resLen duration)


updateStats :: Stats -> MVar Stats -> IO ()
updateStats (Stats s e t b d) counters =
	 modifyMVar_ counters (\(Stats s' e' t' b' d') -> pure (Stats (s' + s) (e' + e) (t' + t) (b' + b) (d' + d)))


eval :: [TestResult] -> IO Stats
eval results = do
	stats <- newMVar (Stats 0 0 0 0 0)

	forM_ results $ \res -> do
		let TestResult url status transferred _ = res
		updateStats (Stats 0 0 0 transferred 0) stats
		case status of
			SUCCESS ->
				updateStats (Stats 1 0 0 0 0) stats
			ERROR ->
				updateStats (Stats 0 1 0 0 0) stats
			TIMEOUT ->
				updateStats (Stats 0 0 1 0 0) stats --

	readMVar stats


main :: IO ()
main = do
	urls <- prepUrls
	summary  <- newMVar (Stats 0 0 0 0 0)
	outputs <- newMVar []

	putStrLn "Starting requests..."

	forM_ [1..iterations] $ \i -> do
		printf "Run: %s/%s\n" (show i) (show iterations)

		startTime <- getCurrentTime
		results <- mapConcurrently getHttpResp urls :: IO [TestResult]
		duration <- realToFrac . (`diffUTCTime` startTime) <$> getCurrentTime

		Stats successes errors timeouts transferred _ <- eval results
		let transferredMb = fromIntegral transferred / (1024.0 * 1024.0) :: Float
		let output = printf "%d: Time %.2fs. Sent: %d. Successes: %d. Errors: %d. Timeouts: %d. Transferred: %.2f (%.2f MB/s)"
							  i duration (successes + errors + timeouts) successes errors timeouts transferredMb
							  (transferredMb / duration)

		modifyMVar_ outputs (\s -> return (output:s))
		updateStats (Stats successes errors timeouts transferred duration) summary

		when verbose $ printf "%s\n%s\n\n" seperator output

	putStrLn seperator

	outputs <- readMVar outputs
	forM_ (reverse outputs) $ \s -> putStrLn s

	Stats successes errors timeouts transferred time <- readMVar summary
	let transferredMb = fromIntegral transferred / (1024.0 * 1024.0) :: Float

	putStrLn seperator
	printf "Runs: %d. Average Time: %.2fs. Total Errors: %d. Total Timeouts: %d. Transferred: %.2f MB (%.2f MB/s).\n"
		iterations (time / fromIntegral iterations) errors timeouts transferredMb (transferredMb / time)
	putStrLn seperator
