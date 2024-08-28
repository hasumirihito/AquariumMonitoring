import React, { useState, useEffect } from 'react';
import { styled } from '@mui/material/styles';
import { 
  Container, 
  Typography, 
  Paper, 
  Grid, 
  Select, 
  MenuItem, 
  FormControl,
  InputLabel
} from '@mui/material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { format, subMonths, subWeeks, startOfDay, endOfDay } from 'date-fns';

const StyledPaper = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(2),
  textAlign: 'center',
  color: theme.palette.text.secondary,
}));

const DataValue = styled(Typography)(({ theme }) => ({
  fontSize: '2rem',
  fontWeight: 'bold',
  color: theme.palette.text.primary,
}));

const LastUpdated = styled(Typography)(({ theme }) => ({
  fontSize: '0.8rem',
  color: theme.palette.text.secondary,
}));

const ChartContainer = styled('div')(({ theme }) => ({
  height: 400,
  marginTop: theme.spacing(2),
}));

const AquariumDashboard = () => {
  const [data, setData] = useState([]);
  const [latestData, setLatestData] = useState(null);
  const [timeRange, setTimeRange] = useState('month');

  useEffect(() => {
    fetchData();
  }, [timeRange]);

  const fetchData = async () => {
    let startDate, endDate;
    const now = new Date();

    switch (timeRange) {
      case 'month':
        startDate = subMonths(now, 1);
        endDate = now;
        break;
      case 'week':
        startDate = subWeeks(now, 1);
        endDate = now;
        break;
      case 'day':
        startDate = startOfDay(now);
        endDate = endOfDay(now);
        break;
      default:
        startDate = subMonths(now, 1);
        endDate = now;
    }

    const response = await fetch(`http://192.168.10.19:5000/water_temperature?start_date=${startDate.toISOString()}&end_date=${endDate.toISOString()}`);
    const result = await response.json();

    setData(result.map(item => ({
      ...item,
      timestamp: new Date(item.timestamp)
    })));

    if (result.length > 0) {
      setLatestData(result[0]);
    }
  };

  const formatXAxis = (tickItem) => {
    switch (timeRange) {
      case 'month':
      case 'week':
        return format(new Date(tickItem), 'MM/dd');
      case 'day':
        return format(new Date(tickItem), 'HH:mm');
      default:
        return tickItem;
    }
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" gutterBottom>
        Aquarium Monitoring Dashboard
      </Typography>
      
      <Grid container spacing={3}>
        {latestData && (
          <>
            <Grid item xs={12} sm={4}>
              <StyledPaper>
                <Typography variant="h6">Water Temperature</Typography>
                <DataValue>{latestData.temperature}°C</DataValue>
                <LastUpdated>
                  Last updated: {format(new Date(latestData.timestamp), 'yyyy-MM-dd HH:mm:ss')}
                </LastUpdated>
              </StyledPaper>
            </Grid>
            <Grid item xs={12} sm={4}>
              <StyledPaper>
                <Typography variant="h6">Air Temperature</Typography>
                <DataValue>{latestData.air_temperature}°C</DataValue>
                <LastUpdated>
                  Last updated: {format(new Date(latestData.timestamp), 'yyyy-MM-dd HH:mm:ss')}
                </LastUpdated>
              </StyledPaper>
            </Grid>
            <Grid item xs={12} sm={4}>
              <StyledPaper>
                <Typography variant="h6">Humidity</Typography>
                <DataValue>{latestData.humidity}%</DataValue>
                <LastUpdated>
                  Last updated: {format(new Date(latestData.timestamp), 'yyyy-MM-dd HH:mm:ss')}
                </LastUpdated>
              </StyledPaper>
            </Grid>
          </>
        )}
        
        <Grid item xs={12}>
          <StyledPaper>
            <Grid container justifyContent="space-between" alignItems="center">
              <Grid item>
                <Typography variant="h6">Historical Data</Typography>
              </Grid>
              <Grid item>
                <FormControl sx={{ m: 1, minWidth: 120 }}>
                  <InputLabel id="time-range-label">Time Range</InputLabel>
                  <Select
                    labelId="time-range-label"
                    value={timeRange}
                    label="Time Range"
                    onChange={(e) => setTimeRange(e.target.value)}
                  >
                    <MenuItem value="month">1 Month</MenuItem>
                    <MenuItem value="week">1 Week</MenuItem>
                    <MenuItem value="day">1 Day</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
            <ChartContainer>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="timestamp"
                    tickFormatter={formatXAxis}
                    type="number"
                    domain={['dataMin', 'dataMax']}
                    scale="time"
                  />
                  <YAxis />
                  <Tooltip
                    labelFormatter={(value) => format(new Date(value), 'yyyy-MM-dd HH:mm:ss')}
                  />
                  <Legend />
                  <Line type="monotone" dataKey="temperature" name="Water Temp" stroke="#1976d2" strokeWidth={2} />
                  <Line type="monotone" dataKey="air_temperature" name="Air Temp" stroke="#388e3c" strokeWidth={2} />
                  <Line type="monotone" dataKey="humidity" name="Humidity" stroke="#f57c00" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </ChartContainer>
          </StyledPaper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default AquariumDashboard;